# Azure Private DNS Zone Module
# This module creates Azure Private DNS Zones and virtual network links

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Data source to get current client configuration
data "azurerm_client_config" "current" {}

# Local values
locals {
  # Common tags applied to all resources
  common_tags = merge(
    {
      "Environment"    = var.environment
      "Project"        = var.project_name
      "Application"    = var.app_name
      "ManagedBy"      = "Terraform"
      "CreatedBy"      = data.azurerm_client_config.current.client_id
      "CreatedDate"    = formatdate("YYYY-MM-DD", timestamp())
    },
    var.additional_tags
  )
}

# Create private DNS zones
resource "azurerm_private_dns_zone" "main" {
  for_each = var.private_dns_zones
  
  name                = each.value.zone_name
  resource_group_name = var.resource_group_name
  
  tags = local.common_tags

  lifecycle {
    # Prevent accidental deletion
    prevent_destroy = var.prevent_destroy
    
    # Ignore changes to tags that are managed by external processes
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"]
    ]
  }
}

# Create virtual network links for each DNS zone
resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  for_each = {
    for link in local.virtual_network_links : "${link.zone_key}-${link.vnet_name}" => link
  }
  
  name                  = each.value.link_name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.main[each.value.zone_key].name
  virtual_network_id    = each.value.virtual_network_id
  registration_enabled  = each.value.registration_enabled
  
  tags = local.common_tags

  lifecycle {
    # Prevent accidental deletion
    prevent_destroy = var.prevent_destroy
    
    # Ignore changes to tags that are managed by external processes
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"]
    ]
  }
}

# Local values for virtual network links
locals {
  # Flatten virtual network links for each DNS zone
  virtual_network_links = flatten([
    for zone_key, zone in var.private_dns_zones : [
      for vnet_link in zone.virtual_network_links : {
        zone_key            = zone_key
        vnet_name          = vnet_link.name
        link_name          = vnet_link.link_name != null ? vnet_link.link_name : "${zone_key}-${vnet_link.name}-link"
        virtual_network_id = vnet_link.virtual_network_id
        registration_enabled = vnet_link.registration_enabled
      }
    ]
  ])
}
