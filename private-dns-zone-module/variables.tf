# Variables for Azure Private DNS Zone Module

variable "private_dns_zones" {
  description = "Map of private DNS zones to create with their virtual network links"
  type = map(object({
    zone_name = string
    virtual_network_links = list(object({
      name                = string
      virtual_network_id  = string
      link_name          = optional(string)
      registration_enabled = optional(bool, false)
    }))
  }))
  validation {
    condition = alltrue([
      for zone_key, zone in var.private_dns_zones : can(regex("^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$", zone.zone_name)) && length(zone.zone_name) >= 2
    ])
    error_message = "Private DNS zone names must be valid domain names with at least 2 labels (e.g., 'contoso.com')."
  }
  validation {
    condition = alltrue([
      for zone_key, zone in var.private_dns_zones : alltrue([
        for link in zone.virtual_network_links : can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_.]{0,79}$", link.name))
      ])
    ])
    error_message = "Virtual network link names must be between 1-80 characters, start with alphanumeric, and contain only alphanumeric, hyphens, underscores, and periods."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where the private DNS zones will be created"
  type        = string
  validation {
    condition = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1-90 characters."
  }
}

variable "location" {
  description = "Azure region where the private DNS zones will be created"
  type        = string
  default     = "UK South"
  validation {
    condition = can(regex("^[a-zA-Z ]+$", var.location))
    error_message = "Location must contain only letters and spaces."
  }
}

variable "project_name" {
  description = "Full name of the project. Used for tagging and documentation"
  type        = string
  validation {
    condition = length(var.project_name) >= 1 && length(var.project_name) <= 50
    error_message = "Project name must be between 1-50 characters."
  }
}

variable "app_name" {
  description = "Full name of the application. Used for tagging and documentation"
  type        = string
  validation {
    condition = length(var.app_name) >= 1 && length(var.app_name) <= 50
    error_message = "App name must be between 1-50 characters."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition = contains(["dev", "staging", "prod", "test", "uat"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test, uat."
  }
}

variable "prevent_destroy" {
  description = "Prevent accidental deletion of the private DNS zone"
  type        = bool
  default     = false
}

variable "additional_tags" {
  description = "Additional tags to apply to the private DNS zone"
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([
      for k, v in var.additional_tags : can(regex("^[a-zA-Z0-9-_.]+$", k))
    ])
    error_message = "Tag keys must contain only alphanumeric characters, hyphens, underscores, and periods."
  }
}
