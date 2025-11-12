# Variables for Azure Key Vault Module

# Key Vault Configuration
variable "key_vault_name" {
  description = "Name of the key vault. If not provided, will be generated using naming convention"
  type        = string
  default     = null
  validation {
    condition = var.key_vault_name == null || (
      can(regex("^[a-zA-Z0-9-]{3,24}$", var.key_vault_name)) &&
      length(var.key_vault_name) >= 3 &&
      length(var.key_vault_name) <= 24
    )
    error_message = "Key vault name must be 3-24 characters long, contain only alphanumeric characters and hyphens, and be globally unique."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where the key vault will be created"
  type        = string
  validation {
    condition = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1-90 characters."
  }
}

variable "location" {
  description = "Azure region where the key vault will be created"
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

# Key Vault Settings
variable "sku_name" {
  description = "The Name of the SKU used for this Key Vault. Possible values are 'standard' and 'premium'"
  type        = string
  default     = "standard"
  validation {
    condition = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU name must be either 'standard' or 'premium'."
  }
}

# Private Endpoint Configuration
variable "subnet_id" {
  description = "The ID of the subnet from which private IP addresses will be allocated for this Private Endpoint"
  type        = string
  validation {
    condition = can(regex("^/subscriptions/.*/resourceGroups/.*/providers/Microsoft.Network/virtualNetworks/.*/subnets/.*$", var.subnet_id))
    error_message = "Subnet ID must be a valid Azure subnet resource ID."
  }
}

variable "private_dns_zone_id" {
  description = "The ID of the private DNS zone to register the private endpoints"
  type        = string
  validation {
    condition = can(regex("^/subscriptions/.*/resourceGroups/.*/providers/Microsoft.Network/privateDnsZones/.*$", var.private_dns_zone_id))
    error_message = "Private DNS zone ID must be a valid Azure private DNS zone resource ID."
  }
}

# Security and Compliance Settings
variable "purge_protection_enabled" {
  description = "Is Purge Protection enabled for this Key Vault?"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days"
  type        = number
  default     = 90
  validation {
    condition = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 7 and 90."
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

variable "additional_tags" {
  description = "Additional tags to apply to the key vault"
  type        = map(string)
  default     = {}
}
