# Subnet Configuration
variable "subnet_name" {
  description = "Name of the subnet. If not provided, will be generated using naming convention"
  type        = string
  default     = null
}

variable "vnet_id" {
  description = "The ID of the virtual network where the subnet will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where the subnet will be created"
  type        = string
  validation {
    condition = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1-90 characters."
  }
}

variable "location" {
  description = "Azure region where the subnet will be created"
  type        = string
  default     = "UK South"
  validation {
    condition = can(regex("^[a-zA-Z ]+$", var.location))
    error_message = "Location must contain only letters and spaces."
  }
}

# Subnet Address Space
variable "address_prefixes" {
  description = "The address prefixes to use for the subnet"
  type        = list(string)
  validation {
    condition = length(var.address_prefixes) >= 1 && length(var.address_prefixes) <= 1000
    error_message = "Address prefixes must contain between 1 and 1000 CIDR blocks."
  }
}

# Naming Convention Variables (from storage-account-module)
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

# Network Security Group Configuration
variable "create_nsg" {
  description = "Whether to create a Network Security Group for the subnet"
  type        = bool
  default     = true
}

variable "nsg_name" {
  description = "Name of the Network Security Group. If not provided, will be generated using naming convention"
  type        = string
  default     = null
}

variable "nsg_rules" {
  description = "List of Network Security Group rules to create"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = optional(string)
    source_port_ranges         = optional(list(string))
    destination_port_range     = optional(string)
    destination_port_ranges    = optional(list(string))
    source_address_prefix      = optional(string)
    source_address_prefixes    = optional(list(string))
    destination_address_prefix = optional(string)
    destination_address_prefixes = optional(list(string))
    description                = optional(string)
  }))
  default = []
  validation {
    condition = alltrue([
      for rule in var.nsg_rules : contains(["Inbound", "Outbound"], rule.direction)
    ])
    error_message = "NSG rule direction must be either 'Inbound' or 'Outbound'."
  }
  validation {
    condition = alltrue([
      for rule in var.nsg_rules : contains(["Allow", "Deny"], rule.access)
    ])
    error_message = "NSG rule access must be either 'Allow' or 'Deny'."
  }
  validation {
    condition = alltrue([
      for rule in var.nsg_rules : contains(["*", "Tcp", "Udp", "Icmp", "Ah", "Esp"], rule.protocol)
    ])
    error_message = "NSG rule protocol must be one of: *, Tcp, Udp, Icmp, Ah, Esp."
  }
}

# Route Table Configuration
variable "create_route_table" {
  description = "Whether to create a Route Table for the subnet"
  type        = bool
  default     = false
}

variable "route_table_name" {
  description = "Name of the Route Table. If not provided, will be generated using naming convention"
  type        = string
  default     = null
}

variable "routes" {
  description = "List of routes to create in the route table"
  type = list(object({
    name           = string
    address_prefix = string
    next_hop_type  = string
    next_hop_in_ip_address = optional(string)
  }))
  default = []
}

# Subnet Service Endpoints
variable "service_endpoints" {
  description = "The list of Service endpoints to associate with the subnet"
  type        = list(string)
  default     = []
}

# Subnet Delegation
variable "delegations" {
  description = "One or more delegation blocks"
  type = list(object({
    name = string
    service_delegation = object({
      name    = string
      actions = optional(list(string))
    })
  }))
  default = []
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
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
