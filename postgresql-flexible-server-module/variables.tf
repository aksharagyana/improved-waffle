# Variables for Azure Database for PostgreSQL - Flexible Server Module

# PostgreSQL Server Configuration
variable "postgresql_server_name" {
  description = "Name of the PostgreSQL server. If not provided, will be generated using naming convention"
  type        = string
  default     = null
  validation {
    condition = var.postgresql_server_name == null || (
      can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.postgresql_server_name)) &&
      length(var.postgresql_server_name) >= 1 &&
      length(var.postgresql_server_name) <= 63
    )
    error_message = "PostgreSQL server name must be 1-63 characters long, contain only lowercase letters, numbers, and hyphens, and start/end with alphanumeric characters."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where the PostgreSQL server will be created"
  type        = string
  validation {
    condition = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1-90 characters."
  }
}

variable "location" {
  description = "Azure region where the PostgreSQL server will be created"
  type        = string
  default     = "UK South"
  validation {
    condition = can(regex("^[a-zA-Z ]+$", var.location))
    error_message = "Location must contain only letters and spaces."
  }
}

# Naming Convention Variables (from storage module)
variable "project_name" {
  description = "Full name of the project. Used for tagging and documentation"
  type        = string
  validation {
    condition = length(var.project_name) >= 1 && length(var.project_name) <= 50
    error_message = "Project name must be between 1-50 characters."
  }
}

variable "project_short" {
  description = "Short name of the project (3-5 characters). Used in resource naming"
  type        = string
  validation {
    condition = can(regex("^[a-z0-9]{3,5}$", var.project_short))
    error_message = "Project short name must be 3-5 characters, lowercase letters and numbers only."
  }
}

variable "app_name" {
  description = "Full name of the application. Used for tagging and documentation"
  type        = string
  validation {
    condition = length(var.app_name) >= 1 && length(var.app_name) <= 50
    error_message = "Application name must be between 1-50 characters."
  }
}

variable "app_short" {
  description = "Short name of the application (3-5 characters). Used in resource naming"
  type        = string
  validation {
    condition = can(regex("^[a-z0-9]{3,5}$", var.app_short))
    error_message = "Application short name must be 3-5 characters, lowercase letters and numbers only."
  }
}

variable "location_short" {
  description = "Short name of the location (3 characters). Used in resource naming (e.g., 'uks' for 'UK South')"
  type        = string
  default     = "uks"
  validation {
    condition = can(regex("^[a-z]{3}$", var.location_short))
    error_message = "Location short name must be exactly 3 lowercase letters."
  }
}

variable "suffix" {
  description = "Suffix for resource naming (2 characters). Used to differentiate resources"
  type        = string
  default     = "01"
  validation {
    condition = can(regex("^[0-9]{2}$", var.suffix))
    error_message = "Suffix must be exactly 2 digits."
  }
}

# Private Networking Configuration
variable "subnet_id" {
  description = "The ID of the subnet where the PostgreSQL server will be deployed"
  type        = string
  validation {
    condition = can(regex("^/subscriptions/.*/resourceGroups/.*/providers/Microsoft.Network/virtualNetworks/.*/subnets/.*$", var.subnet_id))
    error_message = "Subnet ID must be a valid Azure subnet resource ID."
  }
}

variable "private_dns_zone_id" {
  description = "The ID of the private DNS zone for the PostgreSQL server"
  type        = string
  validation {
    condition = can(regex("^/subscriptions/.*/resourceGroups/.*/providers/Microsoft.Network/privateDnsZones/.*$", var.private_dns_zone_id))
    error_message = "Private DNS zone ID must be a valid Azure private DNS zone resource ID."
  }
}

# PostgreSQL Configuration
variable "postgresql_version" {
  description = "Version of PostgreSQL to use"
  type        = string
  default     = "15"
  validation {
    condition = contains(["11", "12", "13", "14", "15", "16"], var.postgresql_version)
    error_message = "PostgreSQL version must be one of: 11, 12, 13, 14, 15, 16."
  }
}

variable "administrator_login" {
  description = "The administrator login name for the PostgreSQL server"
  type        = string
  default     = "psqladmin"
  validation {
    condition = can(regex("^[a-zA-Z][a-zA-Z0-9]*$", var.administrator_login)) && length(var.administrator_login) >= 1 && length(var.administrator_login) <= 32
    error_message = "Administrator login must be 1-32 characters, start with a letter, and contain only alphanumeric characters."
  }
}

variable "administrator_password" {
  description = "The administrator password for the PostgreSQL server"
  type        = string
  sensitive   = true
  validation {
    condition = length(var.administrator_password) >= 8 && length(var.administrator_password) <= 128
    error_message = "Administrator password must be between 8-128 characters."
  }
}

variable "zone" {
  description = "The availability zone for the PostgreSQL server"
  type        = string
  default     = null
  validation {
    condition = var.zone == null || can(regex("^[1-3]$", var.zone))
    error_message = "Zone must be 1, 2, or 3 if specified."
  }
}

# Storage Configuration
variable "storage_mb" {
  description = "The max storage allowed for the PostgreSQL server in MB"
  type        = number
  default     = 32768
  validation {
    condition = var.storage_mb >= 32 && var.storage_mb <= 16777216
    error_message = "Storage must be between 32 MB and 16,777,216 MB (16 TB)."
  }
}

variable "backup_retention_days" {
  description = "The backup retention days for the PostgreSQL server"
  type        = number
  default     = 7
  validation {
    condition = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "Backup retention days must be between 7-35 days."
  }
}

variable "geo_redundant_backup_enabled" {
  description = "Whether geo-redundant backup is enabled"
  type        = bool
  default     = false
}

# High Availability Configuration
variable "high_availability" {
  description = "High availability configuration for the PostgreSQL server"
  type = object({
    mode                      = optional(string, "Disabled")
    standby_availability_zone = optional(string, null)
  })
  default = {
    mode                      = "Disabled"
    standby_availability_zone = null
  }
  validation {
    condition = contains(["Disabled", "ZoneRedundant", "SameZone"], var.high_availability.mode)
    error_message = "High availability mode must be one of: Disabled, ZoneRedundant, SameZone."
  }
}

# Maintenance Window Configuration
variable "maintenance_window" {
  description = "Maintenance window configuration for the PostgreSQL server"
  type = object({
    day_of_week  = optional(number, 0)
    start_hour   = optional(number, 0)
    start_minute = optional(number, 0)
  })
  default = {
    day_of_week  = 0
    start_hour   = 0
    start_minute = 0
  }
  validation {
    condition = var.maintenance_window.day_of_week >= 0 && var.maintenance_window.day_of_week <= 6
    error_message = "Day of week must be between 0-6 (0=Sunday, 6=Saturday)."
  }
  validation {
    condition = var.maintenance_window.start_hour >= 0 && var.maintenance_window.start_hour <= 23
    error_message = "Start hour must be between 0-23."
  }
  validation {
    condition = var.maintenance_window.start_minute >= 0 && var.maintenance_window.start_minute <= 59
    error_message = "Start minute must be between 0-59."
  }
}

# User Managed Identity Configuration
variable "create_user_assigned_identity" {
  description = "Whether to create a new User Assigned Identity for the PostgreSQL server"
  type        = bool
  default     = true
}

variable "user_assigned_identity_ids" {
  description = "List of User Assigned Identity IDs to use for the PostgreSQL server (required if create_user_assigned_identity is false)"
  type        = list(string)
  default     = []
  validation {
    condition = var.create_user_assigned_identity || length(var.user_assigned_identity_ids) > 0
    error_message = "user_assigned_identity_ids must be provided when create_user_assigned_identity is false."
  }
}

# SKU Configuration
variable "sku_name" {
  description = "The SKU name for the PostgreSQL server"
  type        = string
  default     = "GP_Standard_D2s_v3"
  validation {
    condition = can(regex("^(B_|GP_|MO_)[A-Za-z0-9_]+$", var.sku_name))
    error_message = "SKU name must follow the pattern: B_*, GP_*, or MO_* followed by a valid SKU identifier."
  }
}

# Authentication Configuration
variable "authentication" {
  description = "Authentication configuration for the PostgreSQL server"
  type = object({
    active_directory_auth_enabled = optional(bool, false)
    password_auth_enabled         = optional(bool, true)
  })
  default = {
    active_directory_auth_enabled = false
    password_auth_enabled         = true
  }
}

# Customer Managed Key Configuration
variable "customer_managed_key" {
  description = "Customer managed key configuration for the PostgreSQL server"
  type = object({
    key_vault_key_id                    = optional(string, null)
    primary_user_assigned_identity_id   = optional(string, null)
  })
  default = {
    key_vault_key_id                  = null
    primary_user_assigned_identity_id = null
  }
}

# Point in Time Restore Configuration
variable "point_in_time_restore_time_in_utc" {
  description = "The point in time restore time in UTC for the PostgreSQL server"
  type        = string
  default     = null
}

# Replication Role Configuration
variable "replication_role" {
  description = "The replication role for the PostgreSQL server"
  type        = string
  default     = null
  validation {
    condition = var.replication_role == null || contains(["None", "Primary", "Replica"], var.replication_role)
    error_message = "Replication role must be one of: None, Primary, Replica."
  }
}

# PostgreSQL Configurations
variable "postgresql_configurations" {
  description = "Map of PostgreSQL configurations to set on the server"
  type        = map(string)
  default     = {}
}

# Firewall Rules Configuration
variable "firewall_rules" {
  description = "Map of firewall rules to create for the PostgreSQL server"
  type = map(object({
    start_ip_address = string
    end_ip_address   = string
  }))
  default = {}
}

# Database Configuration
variable "databases" {
  description = "Map of databases to create on the PostgreSQL server"
  type = map(object({
    collation = optional(string, "en_US.utf8")
    charset   = optional(string, "utf8")
  }))
  default = {}
}

# Active Directory Administrator Configuration
variable "active_directory_administrator" {
  description = "Active Directory administrator configuration for the PostgreSQL server"
  type = object({
    tenant_id      = string
    object_id      = string
    principal_name = string
    principal_type = string
  })
  default = null
  validation {
    condition = var.active_directory_administrator == null || contains(["User", "Group", "ServicePrincipal"], var.active_directory_administrator.principal_type)
    error_message = "Principal type must be one of: User, Group, ServicePrincipal."
  }
}

# Environment and Lifecycle
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "prevent_destroy" {
  description = "Prevent accidental deletion of the PostgreSQL server"
  type        = bool
  default     = false
}

variable "additional_tags" {
  description = "Additional tags to apply to the PostgreSQL server"
  type        = map(string)
  default     = {}
}
