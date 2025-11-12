# Outputs for Azure Container Registry Module

# Container Registry Outputs
output "acr_id" {
  description = "The ID of the container registry"
  value       = azurerm_container_registry.main.id
}

output "acr_name" {
  description = "The name of the container registry"
  value       = azurerm_container_registry.main.name
}

output "acr_location" {
  description = "The location of the container registry"
  value       = azurerm_container_registry.main.location
}

output "acr_login_server" {
  description = "The login server URL of the container registry"
  value       = azurerm_container_registry.main.login_server
}

output "acr_sku" {
  description = "The SKU of the container registry"
  value       = azurerm_container_registry.main.sku
}

# Private Endpoint Outputs
output "private_endpoint_id" {
  description = "The ID of the private endpoint"
  value       = azurerm_private_endpoint.acr.id
}

output "private_endpoint_name" {
  description = "The name of the private endpoint"
  value       = azurerm_private_endpoint.acr.name
}

output "private_endpoint_fqdn" {
  description = "The FQDN of the private endpoint"
  value       = azurerm_private_endpoint.acr.custom_dns_configs[0].fqdn
}

# Security Configuration Outputs
output "security_settings" {
  description = "Security settings for the container registry"
  value = {
    admin_enabled                    = azurerm_container_registry.main.admin_enabled
    public_network_access_enabled    = azurerm_container_registry.main.public_network_access_enabled
    network_rule_bypass_option       = azurerm_container_registry.main.network_rule_bypass_option
    anonymous_pull_enabled           = azurerm_container_registry.main.anonymous_pull_enabled
    data_endpoint_enabled            = azurerm_container_registry.main.data_endpoint_enabled
    zone_redundancy_enabled          = azurerm_container_registry.main.zone_redundancy_enabled
  }
}

# Common Tags Output
output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}
