#!/bin/bash

# Redis Cluster Client - Kubernetes Deployment Script
# This script builds the Docker image and deploys to Kubernetes

set -e

# Configuration
IMAGE_NAME="redis-cluster-client"
IMAGE_TAG="latest"
REGISTRY=""  # Add your registry if needed, e.g., "myregistry.azurecr.io/"
NAMESPACE="redis"
DEPLOYMENT_FILE="k8s-deployment.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${BLUE}  Redis Cluster Client - K8s Deploy${NC}"
    echo -e "${BLUE}=====================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi

    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi

    # Check if we're connected to Kubernetes
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Not connected to Kubernetes cluster"
        exit 1
    fi

    print_success "Prerequisites check passed"
}

# Build Docker image
build_image() {
    print_info "Building Docker image: ${REGISTRY}${IMAGE_NAME}:${IMAGE_TAG}"

    docker build -t "${REGISTRY}${IMAGE_NAME}:${IMAGE_TAG}" .

    if [ $? -eq 0 ]; then
        print_success "Docker image built successfully"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
}

# Push image to registry (if registry is specified)
push_image() {
    if [ -n "$REGISTRY" ]; then
        print_info "Pushing image to registry: ${REGISTRY}${IMAGE_NAME}:${IMAGE_TAG}"

        docker push "${REGISTRY}${IMAGE_NAME}:${IMAGE_TAG}"

        if [ $? -eq 0 ]; then
            print_success "Image pushed to registry"
        else
            print_error "Failed to push image to registry"
            exit 1
        fi
    else
        print_info "No registry specified, skipping push"
    fi
}

# Check if Redis secret exists
check_redis_secret() {
    print_info "Checking if Redis secret exists..."

    if kubectl get secret redis-secret -n "$NAMESPACE" &> /dev/null; then
        print_success "Redis secret 'redis-secret' found in namespace '$NAMESPACE'"
    else
        print_error "Redis secret 'redis-secret' not found in namespace '$NAMESPACE'"
        print_info "Make sure your Redis Cluster is deployed and the secret exists"
        exit 1
    fi
}

# Check if Redis Cluster is running
check_redis_cluster() {
    print_info "Checking if Redis Cluster is running..."

    local pod_count=$(kubectl get pods -n redis -l app.kubernetes.io/name=redis-cluster --no-headers 2>/dev/null | wc -l)

    if [ "$pod_count" -gt 0 ]; then
        print_success "Found $pod_count Redis Cluster pods"
    else
        print_error "Redis Cluster pods not found"
        print_info "Deploy Redis Cluster first: cd ../ && ./deploy-redis-cluster.sh"
        exit 1
    fi
}

# Deploy to Kubernetes
deploy_to_k8s() {
    print_info "Deploying to Kubernetes namespace: $NAMESPACE"

# Apply the ConfigMap and deployment
kubectl apply -f k8s-configmap.yaml
kubectl apply -f "$DEPLOYMENT_FILE"

    if [ $? -eq 0 ]; then
        print_success "Deployment applied successfully"
    else
        print_error "Failed to apply deployment"
        exit 1
    fi

    # Wait for deployment to be ready
    print_info "Waiting for deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/redis-cluster-client -n "$NAMESPACE" 2>/dev/null || true

    # Check pod status
    local pod_status=$(kubectl get pods -n "$NAMESPACE" -l app=redis-cluster-client --no-headers -o custom-columns=:.status.phase 2>/dev/null | head -1)

    if [ "$pod_status" = "Running" ]; then
        print_success "Pod is running successfully"
    else
        print_info "Pod status: $pod_status"
        print_info "Check logs: kubectl logs -f deployment/redis-cluster-client -n $NAMESPACE"
    fi
}

# Show deployment status
show_status() {
    print_info "Deployment status:"

    echo ""
    echo "Pods:"
    kubectl get pods -n "$NAMESPACE" -l app=redis-cluster-client

    echo ""
    echo "Services:"
    kubectl get svc -n "$NAMESPACE" -l app=redis-cluster-client

    echo ""
    echo "View logs:"
    echo "  kubectl logs -f deployment/redis-cluster-client -n $NAMESPACE"
    echo ""
    echo "Check Redis connection:"
    echo "  kubectl exec -it deployment/redis-cluster-client -n $NAMESPACE -- tail -f /dev/null"
}

# Main execution
main() {
    print_header

    check_prerequisites
    check_redis_secret
    check_redis_cluster
    build_image
    push_image
    deploy_to_k8s
    show_status

    echo ""
    print_success "Deployment completed!"
    print_info "The Redis Cluster client should now be testing your cluster operations."
}

# Run main function
main "$@"
