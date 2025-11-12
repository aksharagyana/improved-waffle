# Variables for Azure Private DNS Resolver Module

# DNS Resolver Configuration
variable "dns_resolver_name" {
  description = "Name of the Private DNS Resolver. If not provided, will be generated using naming convention"
  type        = string
  default     = null
  validation {
    condition = var.dns_resolver_name == null || (
      can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.dns_resolver_name)) &&
      length(var.dns_resolver_name) >= 1 &&
      length(var.dns_resolver_name) <= 63
    )
    error_message = "DNS Resolver name must be 1-63 characters long, contain only lowercase letters, numbers, and hyphens, and start/end with alphanumeric characters."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where the Private DNS Resolver will be created"
  type        = string
  validation {
    condition = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1-90 characters."
  }
}

variable "location" {
  description = "Azure region where the Private DNS Resolver will be created"
  type        = string
  default     = "UK South"
  validation {
    condition = can(regex("^[a-zA-Z ]+$", var.location))
    error_message = "Location must contain only letters and spaces."
  }
}

# Naming Convention Variables (from existing modules)
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
  description = "The ID of the subnet where the Private DNS Resolver will be deployed"
  type        = string
  validation {
    condition = can(regex("^/subscriptions/.*/resourceGroups/.*/providers/Microsoft.Network/virtualNetworks/.*/subnets/.*$", var.subnet_id))
    error_message = "Subnet ID must be a valid Azure subnet resource ID."
  }
}

# Inbound Endpoint Configuration
variable "inbound_endpoints" {
  description = "Map of inbound endpoints to create for the Private DNS Resolver"
  type = map(object({
    name = string
    subnet_id = string
    private_ip_allocation_method = optional(string, "Dynamic")
    private_ip_address = optional(string, null)
  }))
  default = {}
  validation {
    condition = alltrue([
      for k, v in var.inbound_endpoints : can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", v.name))
    ])
    error_message = "Inbound endpoint names must be 1-63 characters long, contain only lowercase letters, numbers, and hyphens, and start/end with alphanumeric characters."
  }
  validation {
    condition = alltrue([
      for k, v in var.inbound_endpoints : can(regex("^/subscriptions/.*/resourceGroups/.*/providers/Microsoft.Network/virtualNetworks/.*/subnets/.*$", v.subnet_id))
    ])
    error_message = "Inbound endpoint subnet IDs must be valid Azure subnet resource IDs."
  }
  validation {
    condition = alltrue([
      for k, v in var.inbound_endpoints : contains(["Dynamic", "Static"], v.private_ip_allocation_method)
    ])
    error_message = "Private IP allocation method must be either 'Dynamic' or 'Static'."
  }
  validation {
    condition = alltrue([
      for k, v in var.inbound_endpoints : v.private_ip_allocation_method == "Dynamic" || v.private_ip_address != null
    ])
    error_message = "private_ip_address must be provided when private_ip_allocation_method is 'Static'."
  }
  validation {
    condition = alltrue([
      for k, v in var.inbound_endpoints : v.private_ip_address == null || can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", v.private_ip_address))
    ])
    error_message = "Private IP address must be a valid IPv4 address when specified."
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
  description = "Prevent accidental deletion of the Private DNS Resolver"
  type        = bool
  default     = false
}

variable "additional_tags" {
  description = "Additional tags to apply to the Private DNS Resolver"
  type        = map(string)
  default     = {}
}
