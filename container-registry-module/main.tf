# Azure Container Registry Module
# This module creates an Azure Container Registry with private endpoints only

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

# Create the container registry
resource "azurerm_container_registry" "main" {
  name                = local.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false  # Disable admin access, use RBAC only
  
  # Security settings
  public_network_access_enabled = false  # Force private access only
  network_rule_bypass_option    = "None" # No bypass options for maximum security
  
  # Note: Encryption, retention policy, and trust policy are not directly configurable
  # in the azurerm_container_registry resource. These features are managed through
  # Azure CLI or Azure Portal after the registry is created.
  
  # Anonymous pull disabled for security
  anonymous_pull_enabled = false
  
  # Data endpoint disabled for private access only
  data_endpoint_enabled = false
  
  # Zone redundancy
  zone_redundancy_enabled = var.zone_redundancy_enabled
  
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

# Create private endpoint for container registry
resource "azurerm_private_endpoint" "acr" {
  name                = "${local.acr_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${local.acr_name}-psc"
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${local.acr_name}-dns-zone-group"
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

# Local values for ACR naming
locals {
  # Generate ACR name if not provided
  acr_name = var.acr_name != null ? var.acr_name : "acr${replace(var.location_short, "-", "")}${var.project_short}${var.app_short}${var.suffix}"
}
