# Variables for Azure Storage Account Module

# Storage Account Configuration
variable "storage_account_name" {
  description = "Name of the storage account. If not provided, will be generated using naming convention"
  type        = string
  default     = null
  validation {
    condition = var.storage_account_name == null || (
      can(regex("^[a-z0-9]{3,24}$", var.storage_account_name)) &&
      length(var.storage_account_name) >= 3 &&
      length(var.storage_account_name) <= 24
    )
    error_message = "Storage account name must be 3-24 characters long, contain only lowercase letters and numbers, and be globally unique."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where the storage account will be created"
  type        = string
  validation {
    condition     = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1-90 characters."
  }
}

variable "location" {
  description = "Azure region where the storage account will be created"
  type        = string
  default     = "UK South"
  validation {
    condition     = can(regex("^[a-zA-Z ]+$", var.location))
    error_message = "Location must contain only letters and spaces."
  }
}

# Naming Convention Variables (from DNS module)
variable "project_name" {
  description = "Full name of the project. Used for tagging and documentation"
  type        = string
  validation {
    condition     = length(var.project_name) >= 1 && length(var.project_name) <= 50
    error_message = "Project name must be between 1-50 characters."
  }
}

variable "project_short" {
  description = "Short name of the project (3-5 characters). Used in resource naming"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,5}$", var.project_short))
    error_message = "Project short name must be 3-5 characters, lowercase letters and numbers only."
  }
}

variable "app_name" {
  description = "Full name of the application. Used for tagging and documentation"
  type        = string
  validation {
    condition     = length(var.app_name) >= 1 && length(var.app_name) <= 50
    error_message = "Application name must be between 1-50 characters."
  }
}

variable "app_short" {
  description = "Short name of the application (3-5 characters). Used in resource naming"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,5}$", var.app_short))
    error_message = "Application short name must be 3-5 characters, lowercase letters and numbers only."
  }
}

variable "location_short" {
  description = "Short name of the location (3 characters). Used in resource naming (e.g., 'uks' for 'UK South')"
  type        = string
  default     = "uks"
  validation {
    condition     = can(regex("^[a-z]{3}$", var.location_short))
    error_message = "Location short name must be exactly 3 lowercase letters."
  }
}

variable "suffix" {
  description = "Suffix for resource naming (2 characters). Used to differentiate resources"
  type        = string
  default     = "01"
  validation {
    condition     = can(regex("^[0-9]{2}$", var.suffix))
    error_message = "Suffix must be exactly 2 digits."
  }
}

# Storage Account Settings
variable "account_tier" {
  description = "Defines the Tier to use for this storage account. Valid options are Standard and Premium"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be either 'Standard' or 'Premium'."
  }
}

variable "account_replication_type" {
  description = "Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS"
  type        = string
  default     = "LRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Account replication type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

# Blob Storage Configuration
variable "create_blob_container" {
  description = "Whether to create a blob container"
  type        = bool
  default     = true
}

variable "blob_container_name" {
  description = "Name of the blob container to create"
  type        = string
  default     = "data"
  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.blob_container_name)) && length(var.blob_container_name) >= 3 && length(var.blob_container_name) <= 63
    error_message = "Blob container name must be 3-63 characters, start and end with alphanumeric, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "blob_container_access_type" {
  description = "The access level configured for the container. Must be either 'blob', 'container' or 'private'"
  type        = string
  default     = "private"
  validation {
    condition     = contains(["blob", "container", "private"], var.blob_container_access_type)
    error_message = "Blob container access type must be 'blob', 'container', or 'private'."
  }
}

variable "blob_versioning_enabled" {
  description = "Is versioning enabled for the blob service"
  type        = bool
  default     = false
}

variable "blob_change_feed_enabled" {
  description = "Is the blob service properties for change feed events enabled"
  type        = bool
  default     = false
}

variable "blob_change_feed_retention_days" {
  description = "The duration of change feed events retention in days"
  type        = number
  default     = 0
  validation {
    condition     = var.blob_change_feed_retention_days >= 0 && var.blob_change_feed_retention_days <= 146000
    error_message = "Blob change feed retention days must be between 0 and 146000."
  }
}

variable "blob_delete_retention_days" {
  description = "Specifies the number of days that the blob should be retained, between 1 and 365 days"
  type        = number
  default     = 7
  validation {
    condition     = var.blob_delete_retention_days >= 1 && var.blob_delete_retention_days <= 365
    error_message = "Blob delete retention days must be between 1 and 365."
  }
}

variable "container_delete_retention_days" {
  description = "Specifies the number of days that the container should be retained, between 1 and 365 days"
  type        = number
  default     = 7
  validation {
    condition     = var.container_delete_retention_days >= 1 && var.container_delete_retention_days <= 365
    error_message = "Container delete retention days must be between 1 and 365."
  }
}

# Queue Storage Configuration
variable "create_queue" {
  description = "Whether to create a queue"
  type        = bool
  default     = true
}

variable "queue_name" {
  description = "Name of the queue to create"
  type        = string
  default     = "tasks"
  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.queue_name)) && length(var.queue_name) >= 3 && length(var.queue_name) <= 63
    error_message = "Queue name must be 3-63 characters, start and end with alphanumeric, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "queue_logging_delete" {
  description = "Indicates whether all delete requests should be logged"
  type        = bool
  default     = true
}

variable "queue_logging_read" {
  description = "Indicates whether all read requests should be logged"
  type        = bool
  default     = true
}

variable "queue_logging_write" {
  description = "Indicates whether all write requests should be logged"
  type        = bool
  default     = true
}

variable "queue_logging_retention_days" {
  description = "Specifies the number of days that logs will be retained"
  type        = number
  default     = 7
  validation {
    condition     = var.queue_logging_retention_days >= 1 && var.queue_logging_retention_days <= 365
    error_message = "Queue logging retention days must be between 1 and 365."
  }
}

variable "queue_hour_metrics_enabled" {
  description = "Indicates whether hour metrics are enabled for the queue service"
  type        = bool
  default     = true
}

variable "queue_hour_metrics_include_apis" {
  description = "Indicates whether metrics should generate summary statistics for called API operations"
  type        = bool
  default     = true
}

variable "queue_hour_metrics_retention_days" {
  description = "Specifies the number of days that metrics will be retained"
  type        = number
  default     = 7
  validation {
    condition     = var.queue_hour_metrics_retention_days >= 1 && var.queue_hour_metrics_retention_days <= 365
    error_message = "Queue hour metrics retention days must be between 1 and 365."
  }
}

variable "queue_minute_metrics_enabled" {
  description = "Indicates whether minute metrics are enabled for the queue service"
  type        = bool
  default     = false
}

variable "queue_minute_metrics_include_apis" {
  description = "Indicates whether metrics should generate summary statistics for called API operations"
  type        = bool
  default     = true
}

variable "queue_minute_metrics_retention_days" {
  description = "Specifies the number of days that metrics will be retained"
  type        = number
  default     = 7
  validation {
    condition     = var.queue_minute_metrics_retention_days >= 1 && var.queue_minute_metrics_retention_days <= 365
    error_message = "Queue minute metrics retention days must be between 1 and 365."
  }
}

# Private Endpoint Configuration
variable "create_private_endpoints" {
  description = "Whether to create private endpoints for blob and queue storage"
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = "The ID of the subnet from which private IP addresses will be allocated for this Private Endpoint"
  type        = string
  validation {
    condition     = can(regex("^/subscriptions/.*/resourceGroups/.*/providers/Microsoft.Network/virtualNetworks/.*/subnets/.*$", var.subnet_id))
    error_message = "Subnet ID must be a valid Azure subnet resource ID."
  }
}

variable "private_dns_zone_id" {
  description = "The ID of the private DNS zone to register the private endpoints"
  type        = string
  validation {
    condition     = can(regex("^/subscriptions/.*/resourceGroups/.*/providers/Microsoft.Network/privateDnsZones/.*$", var.private_dns_zone_id))
    error_message = "Private DNS zone ID must be a valid Azure private DNS zone resource ID."
  }
}

# Network Access Rules
variable "network_rules_default_action" {
  description = "Specifies the default action of allow or deny when no other rules match. Valid options are 'Allow' or 'Deny'"
  type        = string
  default     = "Deny"
  validation {
    condition     = contains(["Allow", "Deny"], var.network_rules_default_action)
    error_message = "Network rules default action must be either 'Allow' or 'Deny'."
  }
}

variable "network_rules_bypass" {
  description = "Specifies whether traffic is bypassed for Logging/Metrics/AzureServices. Valid options are any combination of 'Logging', 'Metrics', 'AzureServices', or 'None'"
  type        = list(string)
  default     = ["Logging", "Metrics", "AzureServices"]
  validation {
    condition = alltrue([
      for bypass in var.network_rules_bypass : contains(["Logging", "Metrics", "AzureServices", "None"], bypass)
    ])
    error_message = "Network rules bypass must be a combination of 'Logging', 'Metrics', 'AzureServices', or 'None'."
  }
}

variable "network_rules_ip_rules" {
  description = "List of public IP or IP ranges in CIDR Format. Only IPV4 addresses are allowed"
  type        = list(string)
  default     = []
}

variable "network_rules_virtual_network_subnet_ids" {
  description = "A list of virtual network subnet ids to to secure the storage account"
  type        = list(string)
  default     = []
}

# Security Settings
variable "enable_https_traffic_only" {
  description = "Boolean flag which forces HTTPS if enabled"
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "The minimum supported TLS version for the storage account. Possible values are TLS1_0, TLS1_1, and TLS1_2"
  type        = string
  default     = "TLS1_2"
  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "Minimum TLS version must be TLS1_0, TLS1_1, or TLS1_2."
  }
}

variable "allow_nested_items_to_be_public" {
  description = "Allow or disallow nested items within this Storage Account to opt into being public"
  type        = bool
  default     = false
}

variable "shared_access_key_enabled" {
  description = "Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Whether the public network access is enabled"
  type        = bool
  default     = false
}

variable "infrastructure_encryption_enabled" {
  description = "Is infrastructure encryption enabled? Changing this forces a new resource to be created"
  type        = bool
  default     = false
}

# Environment and Lifecycle
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "additional_tags" {
  description = "Additional tags to apply to the storage account"
  type        = map(string)
  default     = {}
}
