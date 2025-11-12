# Outputs for Azure Subnet Module

# Subnet Outputs
output "subnet_id" {
  description = "The ID of the subnet"
  value       = azurerm_subnet.main.id
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = azurerm_subnet.main.name
}

output "subnet_address_prefixes" {
  description = "The address prefixes for the subnet"
  value       = azurerm_subnet.main.address_prefixes
}

output "subnet_virtual_network_name" {
  description = "The name of the virtual network in which the subnet is created"
  value       = azurerm_subnet.main.virtual_network_name
}

# Network Security Group Outputs
output "nsg_id" {
  description = "The ID of the Network Security Group"
  value       = var.create_nsg ? azurerm_network_security_group.main[0].id : null
}

output "nsg_name" {
  description = "The name of the Network Security Group"
  value       = var.create_nsg ? azurerm_network_security_group.main[0].name : null
}

output "nsg_location" {
  description = "The location of the Network Security Group"
  value       = var.create_nsg ? azurerm_network_security_group.main[0].location : null
}

output "nsg_rules" {
  description = "The Network Security Group rules"
  value = var.create_nsg ? {
    for rule in azurerm_network_security_rule.main : rule.name => {
      name                        = rule.name
      priority                    = rule.priority
      direction                   = rule.direction
      access                      = rule.access
      protocol                    = rule.protocol
      source_port_range           = rule.source_port_range
      source_port_ranges          = rule.source_port_ranges
      destination_port_range      = rule.destination_port_range
      destination_port_ranges     = rule.destination_port_ranges
      source_address_prefix       = rule.source_address_prefix
      source_address_prefixes     = rule.source_address_prefixes
      destination_address_prefix  = rule.destination_address_prefix
      destination_address_prefixes = rule.destination_address_prefixes
      description                 = rule.description
    }
  } : {}
}

# Route Table Outputs
output "route_table_id" {
  description = "The ID of the Route Table"
  value       = var.create_route_table ? azurerm_route_table.main[0].id : null
}

output "route_table_name" {
  description = "The name of the Route Table"
  value       = var.create_route_table ? azurerm_route_table.main[0].name : null
}

output "route_table_location" {
  description = "The location of the Route Table"
  value       = var.create_route_table ? azurerm_route_table.main[0].location : null
}

output "routes" {
  description = "The routes in the Route Table"
  value = var.create_route_table ? {
    for route in azurerm_route.main : route.name => {
      name                   = route.name
      address_prefix         = route.address_prefix
      next_hop_type          = route.next_hop_type
      next_hop_in_ip_address = route.next_hop_in_ip_address
    }
  } : {}
}

# Service Endpoints Output
output "service_endpoints" {
  description = "The service endpoints associated with the subnet"
  value       = azurerm_subnet.main.service_endpoints
}

# Delegations Output
output "delegations" {
  description = "The delegations associated with the subnet"
  value       = azurerm_subnet.main.delegation
}

# Common Tags Output
output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}
