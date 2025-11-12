# Outputs for Azure Database for PostgreSQL - Flexible Server Module

# PostgreSQL Server Outputs
output "postgresql_server_id" {
  description = "The ID of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.id
}

output "postgresql_server_name" {
  description = "The name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "postgresql_server_fqdn" {
  description = "The FQDN of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgresql_server_version" {
  description = "The version of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.version
}

output "postgresql_server_zone" {
  description = "The availability zone of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.zone
}

output "postgresql_server_public_network_access_enabled" {
  description = "Whether public network access is enabled"
  value       = azurerm_postgresql_flexible_server.main.public_network_access_enabled
}

output "postgresql_server_delegated_subnet_id" {
  description = "The delegated subnet ID of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.delegated_subnet_id
}

output "postgresql_server_private_dns_zone_id" {
  description = "The private DNS zone ID of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.private_dns_zone_id
}

# Storage Outputs
output "postgresql_server_storage_mb" {
  description = "The storage size in MB of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.storage_mb
}

output "postgresql_server_backup_retention_days" {
  description = "The backup retention days of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.backup_retention_days
}

output "postgresql_server_geo_redundant_backup_enabled" {
  description = "Whether geo-redundant backup is enabled"
  value       = azurerm_postgresql_flexible_server.main.geo_redundant_backup_enabled
}

# High Availability Outputs
output "postgresql_server_high_availability" {
  description = "The high availability configuration of the PostgreSQL server"
  value = {
    mode                      = azurerm_postgresql_flexible_server.main.high_availability[0].mode
    standby_availability_zone = azurerm_postgresql_flexible_server.main.high_availability[0].standby_availability_zone
  }
}

# Maintenance Window Outputs
output "postgresql_server_maintenance_window" {
  description = "The maintenance window of the PostgreSQL server"
  value = {
    day_of_week  = azurerm_postgresql_flexible_server.main.maintenance_window[0].day_of_week
    start_hour   = azurerm_postgresql_flexible_server.main.maintenance_window[0].start_hour
    start_minute = azurerm_postgresql_flexible_server.main.maintenance_window[0].start_minute
  }
}

# Identity Outputs
output "postgresql_server_identity" {
  description = "The identity of the PostgreSQL server"
  value = {
    type         = azurerm_postgresql_flexible_server.main.identity[0].type
    principal_id = azurerm_postgresql_flexible_server.main.identity[0].principal_id
    tenant_id    = azurerm_postgresql_flexible_server.main.identity[0].tenant_id
  }
}

output "user_assigned_identity_id" {
  description = "The ID of the User Assigned Identity created for the PostgreSQL server"
  value       = var.create_user_assigned_identity ? azurerm_user_assigned_identity.postgresql[0].id : null
}

output "user_assigned_identity_principal_id" {
  description = "The Principal ID of the User Assigned Identity created for the PostgreSQL server"
  value       = var.create_user_assigned_identity ? azurerm_user_assigned_identity.postgresql[0].principal_id : null
}

output "user_assigned_identity_client_id" {
  description = "The Client ID of the User Assigned Identity created for the PostgreSQL server"
  value       = var.create_user_assigned_identity ? azurerm_user_assigned_identity.postgresql[0].client_id : null
}

# SKU Outputs
output "postgresql_server_sku_name" {
  description = "The SKU name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.sku_name
}

# Authentication Outputs
output "postgresql_server_authentication" {
  description = "The authentication configuration of the PostgreSQL server"
  value = {
    active_directory_auth_enabled = azurerm_postgresql_flexible_server.main.authentication[0].active_directory_auth_enabled
    password_auth_enabled         = azurerm_postgresql_flexible_server.main.authentication[0].password_auth_enabled
    tenant_id                     = azurerm_postgresql_flexible_server.main.authentication[0].tenant_id
  }
}

# Customer Managed Key Outputs
output "postgresql_server_customer_managed_key" {
  description = "The customer managed key configuration of the PostgreSQL server"
  value = {
    key_vault_key_id                  = azurerm_postgresql_flexible_server.main.customer_managed_key[0].key_vault_key_id
    primary_user_assigned_identity_id = azurerm_postgresql_flexible_server.main.customer_managed_key[0].primary_user_assigned_identity_id
  }
}

# Replication Role Outputs
output "postgresql_server_replication_role" {
  description = "The replication role of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.replication_role
}

# Configuration Outputs
output "postgresql_configurations" {
  description = "The PostgreSQL configurations set on the server"
  value = {
    for k, v in azurerm_postgresql_flexible_server_configuration.main : k => {
      name  = v.name
      value = v.value
    }
  }
}

# Firewall Rules Outputs
output "postgresql_firewall_rules" {
  description = "The firewall rules of the PostgreSQL server"
  value = {
    for k, v in azurerm_postgresql_flexible_server_firewall_rule.main : k => {
      name             = v.name
      start_ip_address = v.start_ip_address
      end_ip_address   = v.end_ip_address
    }
  }
}

# Database Outputs
output "postgresql_databases" {
  description = "The databases created on the PostgreSQL server"
  value = {
    for k, v in azurerm_postgresql_flexible_server_database.main : k => {
      name      = v.name
      collation = v.collation
      charset   = v.charset
    }
  }
}

# Active Directory Administrator Outputs
output "postgresql_active_directory_administrator" {
  description = "The Active Directory administrator of the PostgreSQL server"
  value = var.active_directory_administrator != null ? {
    tenant_id      = azurerm_postgresql_flexible_server_active_directory_administrator.main[0].tenant_id
    object_id      = azurerm_postgresql_flexible_server_active_directory_administrator.main[0].object_id
    principal_name = azurerm_postgresql_flexible_server_active_directory_administrator.main[0].principal_name
    principal_type = azurerm_postgresql_flexible_server_active_directory_administrator.main[0].principal_type
  } : null
}

# Connection Information
output "postgresql_connection_string" {
  description = "The connection string for the PostgreSQL server"
  value       = "postgresql://${var.administrator_login}:${var.administrator_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/postgres"
  sensitive   = true
}

output "postgresql_host" {
  description = "The hostname of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgresql_port" {
  description = "The port of the PostgreSQL server"
  value       = 5432
}

output "postgresql_username" {
  description = "The administrator username of the PostgreSQL server"
  value       = var.administrator_login
}

# Common Tags Output
output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}
