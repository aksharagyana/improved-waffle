# Outputs for Azure Storage Account Module

# Storage Account Outputs
output "storage_account_id" {
  description = "The ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_location" {
  description = "The primary location of the storage account"
  value       = azurerm_storage_account.main.primary_location
}
