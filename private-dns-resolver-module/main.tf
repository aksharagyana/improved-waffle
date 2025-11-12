# Azure Private DNS Resolver Module
# This module creates a Private DNS Resolver with inbound endpoints for DNS resolution

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


# Create the Private DNS Resolver
resource "azurerm_private_dns_resolver" "main" {
  name                = local.dns_resolver_name
  resource_group_name = var.resource_group_name
  location            = var.location
  virtual_network_id  = data.azurerm_subnet.main.virtual_network_id

  tags = local.common_tags

  lifecycle {
    prevent_destroy = var.prevent_destroy
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"]
    ]
  }
}

# Data source to get subnet information
data "azurerm_subnet" "main" {
  name                 = split("/", var.subnet_id)[10]
  virtual_network_name = split("/", var.subnet_id)[8]
  resource_group_name  = split("/", var.subnet_id)[4]
}

# Create Inbound Endpoints for the Private DNS Resolver
resource "azurerm_private_dns_resolver_inbound_endpoint" "main" {
  for_each = var.inbound_endpoints

  name                    = each.value.name
  private_dns_resolver_id = azurerm_private_dns_resolver.main.id
  location                = var.location
  ip_configurations {
    private_ip_allocation_method = each.value.private_ip_allocation_method
    subnet_id                   = each.value.subnet_id
    private_ip_address          = each.value.private_ip_address
  }

  tags = local.common_tags

  lifecycle {
    prevent_destroy = var.prevent_destroy
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"]
    ]
  }
}


# Local values for DNS Resolver naming
locals {
  # Generate DNS Resolver name if not provided
  dns_resolver_name = var.dns_resolver_name != null ? var.dns_resolver_name : "dns-${var.location_short}-${var.project_short}-${var.app_short}-${var.suffix}"
}
