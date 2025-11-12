# Azure Key Vault Module
# This module creates an Azure Key Vault with private endpoints only

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

# Create the key vault
resource "azurerm_key_vault" "main" {
  name                = local.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name
  
  # Security settings - RBAC only, no access policies
  # Note: enable_rbac_authorization is deprecated, RBAC is enabled by default when no access_policy blocks are present
  purge_protection_enabled  = var.purge_protection_enabled
  soft_delete_retention_days = var.soft_delete_retention_days
  
  # Network access - private only
  public_network_access_enabled = false
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
  
  # Access policies are disabled when RBAC is enabled
  # No access_policy blocks are defined to ensure RBAC-only access
  
  tags = local.common_tags

  lifecycle {
    # Prevent accidental deletion
    prevent_destroy = true
    
    # Ignore changes to tags that are managed by external processes
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"]
    ]
  }
}

# Create private endpoint for key vault
resource "azurerm_private_endpoint" "kv" {
  name                = "${local.key_vault_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${local.key_vault_name}-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${local.key_vault_name}-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  tags = local.common_tags

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"]
    ]
  }
}

# Local values for key vault naming
locals {
  # Generate key vault name if not provided
  key_vault_name = var.key_vault_name != null ? var.key_vault_name : "kv${replace(var.location_short, "-", "")}${var.project_short}${var.app_short}${var.suffix}"
}
