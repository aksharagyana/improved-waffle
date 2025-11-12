# Azure Kubernetes Service (AKS) Module
# This module creates an AKS cluster with private networking and node pools

# Data source to get current Azure client configuration
data "azurerm_client_config" "current" {}

# Local values for common tags
locals {
  # Common tags applied to all resources
  common_tags = merge(
    {
      "Project"     = var.project_name
      "Application" = var.app_name
      "Environment" = var.environment
      "ManagedBy"   = "Terraform"
      "CreatedDate" = formatdate("YYYY-MM-DD", timestamp())
      "LastModified" = formatdate("YYYY-MM-DD", timestamp())
    },
    var.additional_tags
  )
}

# Create User Managed Identity for AKS if required
resource "azurerm_user_assigned_identity" "aks" {
  count               = var.create_user_assigned_identity ? 1 : 0
  name                = "${local.aks_cluster_name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = local.common_tags

  lifecycle {
    prevent_destroy = var.prevent_destroy
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"]
    ]
  }
}

# Create the AKS cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = local.aks_cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = local.aks_cluster_name
  kubernetes_version  = var.kubernetes_version

  # Private cluster configuration
  private_cluster_enabled = true
  private_dns_zone_id     = var.private_dns_zone_id

  # Default node pool configuration
  default_node_pool {
    name                = var.default_node_pool.name
    vm_size             = var.default_node_pool.vm_size
    node_count          = var.default_node_pool.node_count
    vnet_subnet_id      = var.subnet_id
    os_disk_size_gb     = var.default_node_pool.os_disk_size_gb
    os_disk_type        = var.default_node_pool.os_disk_type
    type                = var.default_node_pool.type
    max_pods            = var.default_node_pool.max_pods
    zones               = var.default_node_pool.zones
    orchestrator_version = var.default_node_pool.orchestrator_version
  }

  # Identity configuration
  identity {
    type = "UserAssigned"
    identity_ids = var.create_user_assigned_identity ? [azurerm_user_assigned_identity.aks[0].id] : var.user_assigned_identity_ids
  }

  # Network profile - kubenet only for private cluster
  network_profile {
    network_plugin      = "kubenet"  # Force kubenet for private cluster
    service_cidr        = var.network_profile.service_cidr
    dns_service_ip      = var.network_profile.dns_service_ip
    pod_cidr            = var.network_profile.pod_cidr
    load_balancer_sku   = var.network_profile.load_balancer_sku
    outbound_type       = var.network_profile.outbound_type
  }

  # RBAC configuration
  role_based_access_control_enabled = var.rbac_enabled

  # Azure Policy addon
  azure_policy_enabled = var.addon_profile.azure_policy.enabled

  # Security features
  local_account_disabled = var.local_account_disabled
  sku_tier              = var.sku_tier

  tags = local.common_tags

  lifecycle {
    prevent_destroy = var.prevent_destroy
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"],
      default_node_pool[0].node_count
    ]
  }

  depends_on = [
    azurerm_user_assigned_identity.aks
  ]
}

# Create additional node pools
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.additional_node_pools

  name                  = each.value.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count
  vnet_subnet_id        = var.subnet_id
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_disk_type          = each.value.os_disk_type
  max_pods              = each.value.max_pods
  zones                 = each.value.zones
  orchestrator_version  = each.value.orchestrator_version
  mode                  = each.value.mode
  priority              = each.value.priority
  eviction_policy       = each.value.eviction_policy
  spot_max_price        = each.value.spot_max_price

  tags = local.common_tags

  lifecycle {
    prevent_destroy = var.prevent_destroy
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"],
      node_count
    ]
  }
}

# Local values for AKS cluster naming
locals {
  # Generate AKS cluster name if not provided
  aks_cluster_name = var.aks_cluster_name != null ? var.aks_cluster_name : "aks-${var.location_short}-${var.project_short}-${var.app_short}-${var.suffix}"
}