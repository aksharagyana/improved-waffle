# Redis Cluster Client Application

A Node.js application that demonstrates Redis Cluster operations with comprehensive read/write functionality. Built with multi-stage Docker for optimal production deployment.

## 🚀 Features

- ✅ **Redis Cluster Aware**: Uses ioredis for full cluster support
- ✅ **Comprehensive Operations**: Strings, Lists, Sets, Hashes, Sorted Sets
- ✅ **Hash Slot Testing**: Demonstrates data distribution across cluster
- ✅ **Performance Testing**: Measures throughput and latency
- ✅ **Error Handling**: Proper connection management and retries
- ✅ **Multi-stage Docker**: Optimized production builds
- ✅ **Health Monitoring**: Cluster topology and node status

## 📋 Prerequisites

- Node.js 18+ (for local development)
- Docker & Docker Compose (for containerized deployment)
- Access to Redis Cluster (your `test-redis-cluster` deployment)

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐
│   Node.js App   │────│  Redis Cluster   │
│                 │    │                  │
│ • ioredis       │    │ • 6 nodes        │
│ • Cluster ops   │    │ • 3 masters      │
│ • Error handling│    │ • 3 replicas     │
└─────────────────┘    └──────────────────┘
```

## 🚀 Quick Start

### 1. Environment Setup

```bash
# Set environment variables
export REDIS_HOSTS="test-redis-cluster-0.test-redis-cluster-headless.redis.svc.cluster.local:6379,test-redis-cluster-1.test-redis-cluster-headless.redis.svc.cluster.local:6379,test-redis-cluster-2.test-redis-cluster-headless.redis.svc.cluster.local:6379,test-redis-cluster-3.test-redis-cluster-headless.redis.svc.cluster.local:6379,test-redis-cluster-4.test-redis-cluster-headless.redis.svc.cluster.local:6379,test-redis-cluster-5.test-redis-cluster-headless.redis.svc.cluster.local:6379"

# Get password from your Redis secret
export REDIS_PASSWORD=$(kubectl get secret redis-secret -n redis -o jsonpath='{.data.redis-password}' | base64 --decode)
```

### 2. Run with Docker Compose

```bash
# Build and run
docker-compose up --build

# Run in background
docker-compose up -d

# View logs
docker-compose logs -f redis-cluster-client
```

### 3. Run with Direct Docker

```bash
# Build image
docker build -t redis-cluster-client .

# Run container
docker run --rm \
  -e REDIS_HOSTS="$REDIS_HOSTS" \
  -e REDIS_PASSWORD="$REDIS_PASSWORD" \
  --name redis-cluster-client \
  redis-cluster-client
```

### 4. Local Development

```bash
# Install dependencies
npm install

# Run application
npm start

# Development mode (with auto-reload)
npm run dev
```

### 5. Kubernetes Deployment

```bash
# Build and deploy to Kubernetes
./deploy-to-k8s.sh

# Or manually
docker build -t redis-cluster-client:latest .
kubectl apply -f k8s-deployment.yaml
kubectl logs -f deployment/redis-cluster-client -n redis
```

## 📊 Operations Demonstrated

### 1. Basic Read/Write Operations
- **SET/GET**: String operations
- **MSET/MGET**: Multiple key operations
- **INCR**: Counter operations
- **SETEX**: Keys with expiration

### 2. Hash Slot Distribution
- Keys distributed across cluster nodes
- Hash tag usage for co-location
- Demonstrates cluster sharding

### 3. Data Types Operations
- **Lists**: RPUSH, LLEN, LINDEX
- **Sets**: SADD, SCARD, SISMEMBER
- **Hashes**: HSET, HGET, HGETALL
- **Sorted Sets**: ZADD, ZSCORE, ZRANGE

### 4. Cluster Information
- Cluster state and health
- Node topology and roles
- Slot distribution status

### 5. Performance Testing
- Batch operations benchmarking
- Throughput measurement
- Latency analysis

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `REDIS_HOSTS` | Comma-separated host:port list | `test-redis-cluster-headless.redis.svc.cluster.local:6379` | Yes |
| `REDIS_PASSWORD` | Redis authentication password | Empty | No |

### Host Format

```
# Single node
REDIS_HOSTS="redis-cluster:6379"

# Multiple nodes (recommended)
REDIS_HOSTS="node1:6379,node2:6379,node3:6379"

# Full cluster (your setup)
REDIS_HOSTS="test-redis-cluster-0.test-redis-cluster-headless.redis.svc.cluster.local:6379,test-redis-cluster-1.test-redis-cluster-headless.redis.svc.cluster.local:6379,test-redis-cluster-2.test-redis-cluster-headless.redis.svc.cluster.local:6379,test-redis-cluster-3.test-redis-cluster-headless.redis.svc.cluster.local:6379,test-redis-cluster-4.test-redis-cluster-headless.redis.svc.cluster.local:6379,test-redis-cluster-5.test-redis-cluster-headless.redis.svc.cluster.local:6379"
```

## 🐳 Docker Multi-Stage Build

### Build Stages

```dockerfile
# Stage 1: Builder
FROM node:18-alpine AS builder
# Install dev dependencies
# Build application
# Prune dev dependencies

# Stage 2: Production
FROM node:18-alpine AS production
# Copy only production dependencies
# Run as non-root user
# Minimal attack surface
```

### Image Optimization

- **Builder Stage**: ~150MB (includes dev tools)
- **Production Stage**: ~80MB (runtime only)
- **Security**: Non-root user (uid 1001)
- **Signals**: Proper handling with dumb-init

### Build Commands

```bash
# Build optimized image
docker build -t redis-cluster-client .

# Analyze image layers
docker history redis-cluster-client

# Check image size
docker images redis-cluster-client
```

## 📈 Sample Output

```
🚀 Connecting to Redis Cluster...
📍 Cluster nodes: test-redis-cluster-0:6379, test-redis-cluster-1:6379, ...
✅ Connected to Redis Cluster
🎉 Redis Cluster is ready for operations

🔥 Starting Redis Cluster Operations...

📝 Test 1: Basic Read/Write Operations
  ✓ SET/GET: "Hello Redis Cluster!"
  ✓ MSET/MGET: [value2, value3]
  ✓ INCR: counter = 1
  ✓ SETEX: temporary value = "temporary value"
  ✅ Basic operations completed

🎯 Test 2: Hash Slot Distribution
  ✓ user:123:name → "value_1"
  ✓ user:456:email → "value_2"
  ✓ Hash tags (same slot): [John Doe, john@example.com, 30]
  ✅ Hash slot distribution working

📊 Test 3: Data Types Operations
  ✓ List: length=3, item[1]="item2"
  ✓ Set: size=3, member2 exists=1
  ✓ Hash: field1="value1", all fields: { field1: 'value1', field2: 'value2' }
  ✓ Sorted Set: member2 score=2, range: [ 'member1', '1', 'member2', '2', 'member3', '3' ]
  ✅ Data types operations completed

ℹ️  Test 4: Cluster Information
  📊 Cluster Info:
    - State: ok
    - Slots assigned: 16384
    - Slots ok: 16384
  🖥️  Cluster Nodes: 6
    1. test-redis-cluster-0:6379 (MASTER) [0...5460]
    2. test-redis-cluster-1:6379 (REPLICA) [0...5460]
    ...
  ✅ Cluster information retrieved

⚡ Test 5: Performance Test
  📈 Performance: 100 SET + 100 GET operations
  ⏱️  Duration: 245ms
  🚀 Throughput: ~816 ops/sec
  ✅ Performance test completed

✅ All operations completed successfully!
📊 Redis Cluster is working correctly!
```

## 🧪 Testing Scenarios

### Test with Your Redis Cluster

```bash
# 1. Ensure Redis Cluster is running
kubectl get pods -n redis -l app.kubernetes.io/name=redis-cluster

# 2. Get password
export REDIS_PASSWORD=$(kubectl get secret redis-secret -n redis -o jsonpath='{.data.redis-password}' | base64 --decode)

# 3. Run the client
docker run --rm \
  -e REDIS_HOSTS="test-redis-cluster-0.test-redis-cluster-headless.redis.svc.cluster.local:6379,test-redis-cluster-1.test-redis-cluster-headless.redis.svc.cluster.local:6379,test-redis-cluster-2.test-redis-cluster-headless.redis.svc.cluster.local:6379,test-redis-cluster-3.test-redis-cluster-headless.redis.svc.cluster.local:6379,test-redis-cluster-4.test-redis-cluster-headless.redis.svc.cluster.local:6379,test-redis-cluster-5.test-redis-cluster-headless.redis.svc.cluster.local:6379" \
  -e REDIS_PASSWORD="$REDIS_PASSWORD" \
  redis-cluster-client
```

### Test Failover Scenario

1. **Start the client** in one terminal
2. **Simulate failure** in another terminal:
   ```bash
   # Delete a master pod to trigger failover
   kubectl delete pod test-redis-cluster-0 -n redis
   ```
3. **Watch the client** handle the failover automatically

### Test Local Redis

```bash
# For local Redis testing
export REDIS_HOSTS="localhost:6379"
export REDIS_PASSWORD=""

docker-compose up --build
```

## 🔍 Troubleshooting

### Connection Issues

```bash
# Test basic connectivity
kubectl exec -it test-redis-cluster-0 -n redis -- \
  redis-cli -a "$REDIS_PASSWORD" PING

# Check cluster status
kubectl exec -it test-redis-cluster-0 -n redis -- \
  redis-cli -a "$REDIS_PASSWORD" cluster info

# Verify endpoints
kubectl get svc -n redis
```

### Common Errors

**"Connection timeout"**
```bash
# Check network policies
kubectl get networkpolicy -n redis

# Verify service DNS
nslookup test-redis-cluster-headless.redis.svc.cluster.local
```

**"MOVED redirection" errors**
```bash
# This is normal - client should handle automatically
# If you see this in logs, it's working correctly
```

**"Cluster state: fail"**
```bash
# Check cluster quorum
kubectl exec -it test-redis-cluster-0 -n redis -- \
  redis-cli -a "$REDIS_PASSWORD" cluster nodes
```

### Debug Mode

```bash
# Enable debug logging
export DEBUG=ioredis:*

# Run with verbose output
docker run --rm \
  -e DEBUG=ioredis:* \
  -e REDIS_HOSTS="$REDIS_HOSTS" \
  -e REDIS_PASSWORD="$REDIS_PASSWORD" \
  redis-cluster-client
```

## 📊 Performance Considerations

### Connection Pooling
- ioredis automatically manages connections to all cluster nodes
- Default pool size: ~10 connections per node
- Adjust with `redisOptions.maxRetriesPerRequest`

### Batch Operations
- Use pipelines for multiple operations
- MSET/MGET for multiple keys
- Hash tags to keep related keys together

### Memory Management
- Monitor client memory usage
- Use appropriate data types
- Implement key expiration strategies

## 🔒 Security

### Best Practices

- ✅ Use strong passwords
- ✅ Rotate credentials regularly
- ✅ Limit network access with policies
- ✅ Monitor connection patterns
- ✅ Use TLS if possible (Redis 6+)

### Container Security

- ✅ Non-root user execution
- ✅ Minimal base image (Alpine)
- ✅ No unnecessary packages
- ✅ Read-only filesystem where possible

## 🚀 Kubernetes Deployment

### Prerequisites

1. **Redis Cluster deployed** in the `redis` namespace
2. **Secret exists**: `redis-secret` with key `redis-password`
3. **Docker registry access** (if using external registry)

### Quick Deploy

```bash
# Build and deploy
./deploy-to-k8s.sh

# Or manually:
# 1. Build image
docker build -t redis-cluster-client:latest .

# 2. Deploy to Kubernetes
kubectl apply -f k8s-deployment.yaml

# 3. Check status
kubectl get pods -n redis -l app=redis-cluster-client
kubectl logs -f deployment/redis-cluster-client -n redis
```

### Security Context

The deployment uses the same security settings as the Docker container:

```yaml
securityContext:
  runAsUser: 1001      # Non-root user (matches Docker)
  runAsGroup: 1001
  runAsNonRoot: true
  fsGroup: 1001

containerSecurityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1001      # Matches Docker user
  capabilities:
    drop:
    - ALL
```

### Resource Limits

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

### Deployment Options

#### Option 1: Deployment (Long-running)
- Runs continuously
- Good for monitoring/debugging
- Access via `kubectl logs`

#### Option 2: Job (One-time execution)
- Runs once and exits
- Good for testing/validation
- Uses `batch/v1` Job resource

### Environment Variables

```yaml
env:
- name: REDIS_HOSTS
  value: "test-redis-cluster-0.test-redis-cluster-headless.redis.svc.cluster.local:6379,..."
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: redis-secret
      key: redis-password
```

## 📚 Advanced Usage

### Custom Operations

```javascript
// Add custom operations to app.js
async function customOperations() {
  // Your custom Redis operations here
  await cluster.set('custom:key', 'custom value');
  const result = await cluster.get('custom:key');
  console.log('Custom operation result:', result);
}
```

### Monitoring Integration

```javascript
// Add Prometheus metrics
const promClient = require('prom-client');

// Create metrics
const redisOpsTotal = new promClient.Counter({
  name: 'redis_operations_total',
  help: 'Total Redis operations performed'
});

// Use in operations
redisOpsTotal.inc();
```

### Scaling Considerations

- Monitor connection counts
- Adjust client pool sizes
- Use connection multiplexing
- Implement circuit breakers

## 🤝 Contributing

### Code Structure

```
redis-cluster-client/
├── app.js              # Main application
├── package.json        # Dependencies
├── Dockerfile          # Multi-stage build
├── docker-compose.yml  # Container orchestration
└── README.md          # This file
```

### Development Workflow

```bash
# 1. Clone and install
git clone <repo>
cd redis-cluster-client
npm install

# 2. Make changes
vim app.js

# 3. Test locally
npm start

# 4. Build and test container
docker-compose up --build

# 5. Submit PR
```

## 📄 License

MIT License - feel free to use this code for your Redis Cluster testing needs.

## 🔗 Related Resources

- [Redis Cluster Specification](https://redis.io/docs/reference/cluster-spec/)
- [ioredis Documentation](https://redis.github.io/ioredis/)
- [Docker Multi-Stage Builds](https://docs.docker.com/develop/dev-best-practices/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)

---

**Happy clustering!** 🎉 Test your Redis Cluster thoroughly with this comprehensive client application.
