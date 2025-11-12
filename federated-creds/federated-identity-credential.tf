# Federated Identity Credential for Existing AKS and UMI
# This file creates federated identity credentials for an existing User Managed Identity
# to work with an existing AKS cluster using workload identity

# Data source to get existing AKS cluster information
data "azurerm_kubernetes_cluster" "existing" {
  name                = var.aks_cluster_name
  resource_group_name = var.aks_resource_group_name
}

# Data source to get existing User Managed Identity
data "azurerm_user_assigned_identity" "existing" {
  name                = var.umi_name
  resource_group_name = var.umi_resource_group_name
}

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.existing.kube_admin_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.existing.kube_admin_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.existing.kube_admin_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.existing.kube_admin_config.0.cluster_ca_certificate)
}

# Create namespace if it doesn't exist
resource "kubernetes_namespace" "workload_identity" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.kubernetes_namespace
    labels = {
      "azure.workload.identity/use" = "true"
    }
  }
}

# Create Kubernetes Service Account
resource "kubernetes_service_account" "workload_identity" {
  metadata {
    name      = var.kubernetes_service_account_name
    namespace = var.create_namespace ? kubernetes_namespace.workload_identity[0].metadata[0].name : var.kubernetes_namespace
    labels = {
      "azure.workload.identity/use" = "true"
    }
    annotations = {
      "azure.workload.identity/client-id" = data.azurerm_user_assigned_identity.existing.client_id
    }
  }
}

# Create Federated Identity Credential
resource "azurerm_federated_identity_credential" "workload_identity" {
  name                = var.federated_credential_name
  resource_group_name = var.umi_resource_group_name
  audience            = var.audience
  issuer              = data.azurerm_kubernetes_cluster.existing.oidc_issuer_url
  parent_id           = data.azurerm_user_assigned_identity.existing.id
  subject             = "system:serviceaccount:${kubernetes_service_account.workload_identity.metadata[0].namespace}:${kubernetes_service_account.workload_identity.metadata[0].name}"

  depends_on = [
    kubernetes_service_account.workload_identity
  ]
}

# Optional: Create role assignments for the UMI
resource "azurerm_role_assignment" "umi_assignments" {
  for_each = var.role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = data.azurerm_user_assigned_identity.existing.principal_id
}
