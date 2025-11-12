# Outputs for Azure Private DNS Zone Module

output "private_dns_zones" {
  description = "Map of private DNS zones created with their details"
  value = {
    for zone_key, zone in azurerm_private_dns_zone.main : zone_key => {
      id   = zone.id
      name = zone.name
      fqdn = zone.name
    }
  }
}

output "private_dns_zone_names" {
  description = "List of private DNS zone names"
  value       = [for zone in azurerm_private_dns_zone.main : zone.name]
}

output "private_dns_zone_ids" {
  description = "List of private DNS zone IDs"
  value       = [for zone in azurerm_private_dns_zone.main : zone.id]
}

output "virtual_network_links" {
  description = "Map of virtual network links created with their details"
  value = {
    for key, link in azurerm_private_dns_zone_virtual_network_link.main : key => {
      id                   = link.id
      name                 = link.name
      zone_key            = local.virtual_network_links[key].zone_key
      virtual_network_id   = link.virtual_network_id
      registration_enabled = link.registration_enabled
    }
  }
}
