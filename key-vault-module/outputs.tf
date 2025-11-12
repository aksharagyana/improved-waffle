# Outputs for Azure Key Vault Module

# Key Vault Outputs
output "key_vault_id" {
  description = "The ID of the key vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "The name of the key vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_location" {
  description = "The location of the key vault"
  value       = azurerm_key_vault.main.location
}

output "key_vault_uri" {
  description = "The URI of the key vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_tenant_id" {
  description = "The tenant ID of the key vault"
  value       = azurerm_key_vault.main.tenant_id
}

output "key_vault_sku_name" {
  description = "The SKU name of the key vault"
  value       = azurerm_key_vault.main.sku_name
}

# Private Endpoint Outputs
output "private_endpoint_id" {
  description = "The ID of the private endpoint"
  value       = azurerm_private_endpoint.kv.id
}

output "private_endpoint_name" {
  description = "The name of the private endpoint"
  value       = azurerm_private_endpoint.kv.name
}

output "private_endpoint_fqdn" {
  description = "The FQDN of the private endpoint"
  value       = azurerm_private_endpoint.kv.custom_dns_configs[0].fqdn
}

# Security Configuration Outputs
output "security_settings" {
  description = "Security settings for the key vault"
  value = {
    purge_protection_enabled      = azurerm_key_vault.main.purge_protection_enabled
    soft_delete_retention_days    = azurerm_key_vault.main.soft_delete_retention_days
    public_network_access_enabled = azurerm_key_vault.main.public_network_access_enabled
    rbac_enabled                  = true  # RBAC is enabled by default when no access_policy blocks are present
  }
}

# Common Tags Output
output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}
