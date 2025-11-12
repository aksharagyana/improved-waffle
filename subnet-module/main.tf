# Azure Subnet Module
# This module creates an Azure Subnet with optional Network Security Group and Route Table

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

  # Generate resource names if not provided
  subnet_name = var.subnet_name != null ? var.subnet_name : "snet-${var.location_short}-${var.project_short}-${var.app_short}-${var.suffix}"
  nsg_name = var.nsg_name != null ? var.nsg_name : "nsg-${var.location_short}-${var.project_short}-${var.app_short}-${var.suffix}"
  route_table_name = var.route_table_name != null ? var.route_table_name : "rt-${var.location_short}-${var.project_short}-${var.app_short}-${var.suffix}"
}

# Create Network Security Group
resource "azurerm_network_security_group" "main" {
  count               = var.create_nsg ? 1 : 0
  name                = local.nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = local.common_tags

  lifecycle {
    # Ignore changes to tags that are managed by external processes
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"]
    ]
  }
}

# Create Network Security Group rules
resource "azurerm_network_security_rule" "main" {
  for_each = var.create_nsg ? {
    for rule in var.nsg_rules : rule.name => rule
  } : {}

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  source_port_ranges          = each.value.source_port_ranges
  destination_port_range      = each.value.destination_port_range
  destination_port_ranges     = each.value.destination_port_ranges
  source_address_prefix       = each.value.source_address_prefix
  source_address_prefixes     = each.value.source_address_prefixes
  destination_address_prefix  = each.value.destination_address_prefix
  destination_address_prefixes = each.value.destination_address_prefixes
  description                 = each.value.description
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main[0].name
}

# Create Route Table
resource "azurerm_route_table" "main" {
  count               = var.create_route_table ? 1 : 0
  name                = local.route_table_name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = local.common_tags

  lifecycle {
    # Ignore changes to tags that are managed by external processes
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"]
    ]
  }
}

# Create routes in the route table
resource "azurerm_route" "main" {
  for_each = var.create_route_table ? {
    for route in var.routes : route.name => route
  } : {}

  name                   = each.value.name
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.main[0].name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_in_ip_address
}

# Create the subnet
resource "azurerm_subnet" "main" {
  name                 = local.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = split("/", var.vnet_id)[8]
  address_prefixes     = var.address_prefixes

  # Service endpoints
  service_endpoints = var.service_endpoints

  # Delegations
  dynamic "delegation" {
    for_each = var.delegations
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

# Associate NSG with subnet if created
resource "azurerm_subnet_network_security_group_association" "main" {
  count                     = var.create_nsg ? 1 : 0
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main[0].id
}

# Associate Route Table with subnet if created
resource "azurerm_subnet_route_table_association" "main" {
  count          = var.create_route_table ? 1 : 0
  subnet_id      = azurerm_subnet.main.id
  route_table_id = azurerm_route_table.main[0].id
}
