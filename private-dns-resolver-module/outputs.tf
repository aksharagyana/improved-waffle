# Outputs for Azure Private DNS Resolver Module

# DNS Resolver Outputs
output "dns_resolver_id" {
  description = "The ID of the Private DNS Resolver"
  value       = azurerm_private_dns_resolver.main.id
}

output "dns_resolver_name" {
  description = "The name of the Private DNS Resolver"
  value       = azurerm_private_dns_resolver.main.name
}

output "dns_resolver_location" {
  description = "The location of the Private DNS Resolver"
  value       = azurerm_private_dns_resolver.main.location
}

output "dns_resolver_virtual_network_id" {
  description = "The virtual network ID of the Private DNS Resolver"
  value       = azurerm_private_dns_resolver.main.virtual_network_id
}

# Inbound Endpoints Outputs
output "inbound_endpoints" {
  description = "The inbound endpoints of the Private DNS Resolver"
  value = {
    for k, v in azurerm_private_dns_resolver_inbound_endpoint.main : k => {
      id   = v.id
      name = v.name
      ip_configurations = v.ip_configurations
    }
  }
}

output "inbound_endpoint_ids" {
  description = "The IDs of the inbound endpoints"
  value       = [for k, v in azurerm_private_dns_resolver_inbound_endpoint.main : v.id]
}

output "inbound_endpoint_names" {
  description = "The names of the inbound endpoints"
  value       = [for k, v in azurerm_private_dns_resolver_inbound_endpoint.main : v.name]
}



# Subnet Information Outputs
output "subnet_id" {
  description = "The subnet ID where the Private DNS Resolver is deployed"
  value       = var.subnet_id
}

output "subnet_name" {
  description = "The name of the subnet where the Private DNS Resolver is deployed"
  value       = data.azurerm_subnet.main.name
}

output "subnet_virtual_network_name" {
  description = "The name of the virtual network containing the subnet"
  value       = split("/", data.azurerm_subnet.main.virtual_network_id)[8]
}

output "subnet_resource_group_name" {
  description = "The resource group name of the subnet"
  value       = data.azurerm_subnet.main.resource_group_name
}

# Connection Information
output "dns_resolver_fqdn" {
  description = "The FQDN of the Private DNS Resolver (if available)"
  value       = try(azurerm_private_dns_resolver.main.fqdn, null)
}

output "inbound_endpoint_ip_addresses" {
  description = "The IP addresses of the inbound endpoints"
  value = {
    for k, v in azurerm_private_dns_resolver_inbound_endpoint.main : k => [
      for config in v.ip_configurations : config.private_ip_address
    ]
  }
}

# Common Tags Output
output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}

# Resource Counts
output "inbound_endpoint_count" {
  description = "The number of inbound endpoints created"
  value       = length(azurerm_private_dns_resolver_inbound_endpoint.main)
}
