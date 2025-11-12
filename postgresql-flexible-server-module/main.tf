# Azure Database for PostgreSQL - Flexible Server Module
# This module creates a private PostgreSQL Flexible Server with private networking

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

# Create User Assigned Identity for PostgreSQL if required
resource "azurerm_user_assigned_identity" "postgresql" {
  count               = var.create_user_assigned_identity ? 1 : 0
  name                = "${local.postgresql_server_name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = local.common_tags

  lifecycle {
    prevent_destroy = var.prevent_destroy
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"]
    ]
  }
}

# Create the PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                = local.postgresql_server_name
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = var.postgresql_version

  # Private server configuration
  public_network_access_enabled = false  # Private only
  delegated_subnet_id           = var.subnet_id
  private_dns_zone_id           = var.private_dns_zone_id

  # Server configuration
  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password
  zone                   = var.zone

  # Storage configuration
  storage_mb = var.storage_mb
  backup_retention_days = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  # High availability configuration
  high_availability {
    mode                      = var.high_availability.mode
    standby_availability_zone = var.high_availability.standby_availability_zone
  }

  # Maintenance window
  maintenance_window {
    day_of_week  = var.maintenance_window.day_of_week
    start_hour   = var.maintenance_window.start_hour
    start_minute = var.maintenance_window.start_minute
  }

  # Identity configuration
  identity {
    type         = "UserAssigned"
    identity_ids = var.create_user_assigned_identity ? [azurerm_user_assigned_identity.postgresql[0].id] : var.user_assigned_identity_ids
  }

  # Compute configuration
  sku_name = var.sku_name

  # Authentication configuration
  authentication {
    active_directory_auth_enabled  = var.authentication.active_directory_auth_enabled
    password_auth_enabled          = var.authentication.password_auth_enabled
    tenant_id                      = var.authentication.active_directory_auth_enabled ? data.azurerm_client_config.current.tenant_id : null
  }

  # Customer managed key configuration
  customer_managed_key {
    key_vault_key_id   = var.customer_managed_key.key_vault_key_id
    primary_user_assigned_identity_id = var.customer_managed_key.primary_user_assigned_identity_id
  }

  # Point in time restore configuration
  point_in_time_restore_time_in_utc = var.point_in_time_restore_time_in_utc

  # Replication role
  replication_role = var.replication_role

  tags = local.common_tags

  lifecycle {
    prevent_destroy = var.prevent_destroy
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"],
      zone
    ]
  }

  depends_on = [
    azurerm_user_assigned_identity.postgresql
  ]
}

# Create PostgreSQL Flexible Server Configuration
resource "azurerm_postgresql_flexible_server_configuration" "main" {
  for_each = var.postgresql_configurations

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = each.value
}

# Create PostgreSQL Flexible Server Firewall Rules
resource "azurerm_postgresql_flexible_server_firewall_rule" "main" {
  for_each = var.firewall_rules

  name             = each.key
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

# Create PostgreSQL Flexible Server Database
resource "azurerm_postgresql_flexible_server_database" "main" {
  for_each = var.databases

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = each.value.collation
  charset   = each.value.charset
}

# Create PostgreSQL Flexible Server Active Directory Administrator
resource "azurerm_postgresql_flexible_server_active_directory_administrator" "main" {
  count = var.active_directory_administrator != null ? 1 : 0

  server_name         = azurerm_postgresql_flexible_server.main.name
  resource_group_name = var.resource_group_name
  tenant_id           = var.active_directory_administrator.tenant_id
  object_id           = var.active_directory_administrator.object_id
  principal_name      = var.active_directory_administrator.principal_name
  principal_type      = var.active_directory_administrator.principal_type
}

# Local values for PostgreSQL server naming
locals {
  # Generate PostgreSQL server name if not provided
  postgresql_server_name = var.postgresql_server_name != null ? var.postgresql_server_name : "psql-${var.location_short}-${var.project_short}-${var.app_short}-${var.suffix}"
}
