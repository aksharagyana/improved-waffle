# Outputs for Azure Kubernetes Service (AKS) Module

# AKS Cluster Outputs
output "aks_cluster_id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_cluster_fqdn" {
  description = "The FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "aks_cluster_private_fqdn" {
  description = "The private FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.private_fqdn
}

output "aks_cluster_portal_fqdn" {
  description = "The portal FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.portal_fqdn
}

output "aks_cluster_private_cluster_enabled" {
  description = "Whether the AKS cluster is private"
  value       = azurerm_kubernetes_cluster.main.private_cluster_enabled
}

output "aks_cluster_kubernetes_version" {
  description = "The Kubernetes version of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.kubernetes_version
}

output "aks_cluster_node_resource_group" {
  description = "The name of the resource group containing the AKS cluster nodes"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

# Kubeconfig Outputs
output "kube_config" {
  description = "The Kubernetes configuration for the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "kube_config_client_key" {
  description = "The client key for the Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_key
  sensitive   = true
}

output "kube_config_client_certificate" {
  description = "The client certificate for the Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_certificate
  sensitive   = true
}

output "kube_config_cluster_ca_certificate" {
  description = "The cluster CA certificate for the Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "kube_config_host" {
  description = "The host for the Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive   = true
}

# Identity Outputs
output "aks_cluster_identity" {
  description = "The identity of the AKS cluster"
  value = {
    type         = azurerm_kubernetes_cluster.main.identity[0].type
    principal_id = azurerm_kubernetes_cluster.main.identity[0].principal_id
    tenant_id    = azurerm_kubernetes_cluster.main.identity[0].tenant_id
  }
}

output "user_assigned_identity_id" {
  description = "The ID of the User Assigned Identity created for the AKS cluster"
  value       = var.create_user_assigned_identity ? azurerm_user_assigned_identity.aks[0].id : null
}

output "user_assigned_identity_principal_id" {
  description = "The Principal ID of the User Assigned Identity created for the AKS cluster"
  value       = var.create_user_assigned_identity ? azurerm_user_assigned_identity.aks[0].principal_id : null
}

output "user_assigned_identity_client_id" {
  description = "The Client ID of the User Assigned Identity created for the AKS cluster"
  value       = var.create_user_assigned_identity ? azurerm_user_assigned_identity.aks[0].client_id : null
}

# Network Outputs
output "aks_cluster_network_profile" {
  description = "The network profile of the AKS cluster"
  value = {
    network_plugin    = azurerm_kubernetes_cluster.main.network_profile[0].network_plugin
    service_cidr      = azurerm_kubernetes_cluster.main.network_profile[0].service_cidr
    dns_service_ip    = azurerm_kubernetes_cluster.main.network_profile[0].dns_service_ip
    pod_cidr          = azurerm_kubernetes_cluster.main.network_profile[0].pod_cidr
    load_balancer_sku = azurerm_kubernetes_cluster.main.network_profile[0].load_balancer_sku
    outbound_type     = azurerm_kubernetes_cluster.main.network_profile[0].outbound_type
  }
}

# Default Node Pool Outputs
output "default_node_pool" {
  description = "The default node pool of the AKS cluster"
  value = {
    id                = azurerm_kubernetes_cluster.main.default_node_pool[0].id
    name              = azurerm_kubernetes_cluster.main.default_node_pool[0].name
    vm_size           = azurerm_kubernetes_cluster.main.default_node_pool[0].vm_size
    node_count        = azurerm_kubernetes_cluster.main.default_node_pool[0].node_count
    os_disk_size_gb   = azurerm_kubernetes_cluster.main.default_node_pool[0].os_disk_size_gb
    os_disk_type      = azurerm_kubernetes_cluster.main.default_node_pool[0].os_disk_type
    max_pods          = azurerm_kubernetes_cluster.main.default_node_pool[0].max_pods
    zones             = azurerm_kubernetes_cluster.main.default_node_pool[0].zones
  }
}

# Additional Node Pools Outputs
output "additional_node_pools" {
  description = "The additional node pools of the AKS cluster"
  value = {
    for k, v in azurerm_kubernetes_cluster_node_pool.additional : k => {
      id                = v.id
      name              = v.name
      vm_size           = v.vm_size
      node_count        = v.node_count
      os_disk_size_gb   = v.os_disk_size_gb
      os_disk_type      = v.os_disk_type
      max_pods          = v.max_pods
      zones             = v.zones
      mode              = v.mode
      priority          = v.priority
      eviction_policy   = v.eviction_policy
    }
  }
}

# RBAC Outputs
output "rbac_enabled" {
  description = "Whether RBAC is enabled on the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.role_based_access_control_enabled
}

# Addon Profile Outputs
output "addon_profile" {
  description = "The addon profile of the AKS cluster"
  value = {
    azure_policy = azurerm_kubernetes_cluster.main.azure_policy_enabled
  }
}

# Security Outputs
output "local_account_disabled" {
  description = "Whether local accounts are disabled"
  value       = azurerm_kubernetes_cluster.main.local_account_disabled
}

output "sku_tier" {
  description = "The SKU tier of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.sku_tier
}

# Common Tags Output
output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}