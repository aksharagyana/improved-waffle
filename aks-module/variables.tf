# Variables for Azure Kubernetes Service (AKS) Module

# AKS Cluster Configuration
variable "aks_cluster_name" {
  description = "Name of the AKS cluster. If not provided, will be generated using naming convention"
  type        = string
  default     = null
  validation {
    condition = var.aks_cluster_name == null || (
      can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.aks_cluster_name)) &&
      length(var.aks_cluster_name) >= 1 &&
      length(var.aks_cluster_name) <= 63
    )
    error_message = "AKS cluster name must be 1-63 characters long, contain only lowercase letters, numbers, and hyphens, and start/end with alphanumeric characters."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where the AKS cluster will be created"
  type        = string
  validation {
    condition = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1-90 characters."
  }
}

variable "location" {
  description = "Azure region where the AKS cluster will be created"
  type        = string
  default     = "UK South"
  validation {
    condition = can(regex("^[a-zA-Z ]+$", var.location))
    error_message = "Location must contain only letters and spaces."
  }
}

# Naming Convention Variables (from example module)
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
  description = "The ID of the subnet where the AKS cluster will be deployed"
  type        = string
  validation {
    condition = can(regex("^/subscriptions/.*/resourceGroups/.*/providers/Microsoft.Network/virtualNetworks/.*/subnets/.*$", var.subnet_id))
    error_message = "Subnet ID must be a valid Azure subnet resource ID."
  }
}

variable "private_dns_zone_id" {
  description = "The ID of the private DNS zone for the AKS cluster"
  type        = string
  validation {
    condition = can(regex("^/subscriptions/.*/resourceGroups/.*/providers/Microsoft.Network/privateDnsZones/.*$", var.private_dns_zone_id))
    error_message = "Private DNS zone ID must be a valid Azure private DNS zone resource ID."
  }
}

# Kubernetes Configuration
variable "kubernetes_version" {
  description = "Version of Kubernetes to use for the AKS cluster"
  type        = string
  default     = "1.28"
  validation {
    condition = can(regex("^[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "Kubernetes version must be in format 'X.Y' (e.g., '1.28')."
  }
}

# Default Node Pool Configuration
variable "default_node_pool" {
  description = "Configuration for the default node pool"
  type = object({
    name                = string
    vm_size             = string
    node_count          = number
    os_disk_size_gb     = optional(number, 30)
    os_disk_type        = optional(string, "Ephemeral")
    type                = optional(string, "VirtualMachineScaleSets")
    max_pods            = optional(number, 30)
    zones               = optional(list(string), [])
    orchestrator_version = optional(string, null)
  })
  default = {
    name                = "default"
    vm_size             = "Standard_D2s_v3"
    node_count          = 1
    os_disk_size_gb     = 30
    os_disk_type        = "Ephemeral"
    type                = "VirtualMachineScaleSets"
    max_pods            = 30
    zones               = []
    orchestrator_version = null
  }
}

# Additional Node Pools Configuration
variable "additional_node_pools" {
  description = "Map of additional node pools to create"
  type = map(object({
    name               = string
    vm_size            = string
    node_count         = number
    os_disk_size_gb    = optional(number, 30)
    os_disk_type       = optional(string, "Ephemeral")
    max_pods           = optional(number, 30)
    zones              = optional(list(string), [])
    orchestrator_version = optional(string, null)
    mode               = optional(string, "User")
    priority           = optional(string, "Regular")
    eviction_policy    = optional(string, "Delete")
    spot_max_price     = optional(number, -1)
  }))
  default = {}
}

# User Managed Identity Configuration
variable "create_user_assigned_identity" {
  description = "Whether to create a new User Assigned Identity for the AKS cluster"
  type        = bool
  default     = true
}

variable "user_assigned_identity_ids" {
  description = "List of User Assigned Identity IDs to use for the AKS cluster (required if create_user_assigned_identity is false)"
  type        = list(string)
  default     = []
  validation {
    condition = var.create_user_assigned_identity || length(var.user_assigned_identity_ids) > 0
    error_message = "user_assigned_identity_ids must be provided when create_user_assigned_identity is false."
  }
}

# Network Profile Configuration
variable "network_profile" {
  description = "Network profile configuration for the AKS cluster"
  type = object({
    service_cidr   = optional(string, "10.0.0.0/16")
    dns_service_ip = optional(string, "10.0.0.10")
    pod_cidr       = optional(string, "10.244.0.0/16")
    load_balancer_sku = optional(string, "standard")
    outbound_type  = optional(string, "loadBalancer")
  })
  default = {
    service_cidr   = "10.0.0.0/16"
    dns_service_ip = "10.0.0.10"
    pod_cidr       = "10.244.0.0/16"
    load_balancer_sku = "standard"
    outbound_type  = "loadBalancer"
  }
}

# RBAC Configuration
variable "rbac_enabled" {
  description = "Whether to enable RBAC on the AKS cluster"
  type        = bool
  default     = true
}

# Addon Profile Configuration
variable "addon_profile" {
  description = "Addon profile configuration for the AKS cluster"
  type = object({
    azure_policy = optional(object({
      enabled = bool
    }), { enabled = false })
  })
  default = {
    azure_policy = { enabled = false }
  }
}

# Security Configuration
variable "local_account_disabled" {
  description = "Whether to disable local accounts"
  type        = bool
  default     = false
}

variable "sku_tier" {
  description = "The SKU Tier that should be used for this Kubernetes Cluster"
  type        = string
  default     = "Free"
  validation {
    condition = contains(["Free", "Paid"], var.sku_tier)
    error_message = "SKU tier must be either 'Free' or 'Paid'."
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
  description = "Prevent accidental deletion of the AKS cluster"
  type        = bool
  default     = false
}

variable "additional_tags" {
  description = "Additional tags to apply to the AKS cluster"
  type        = map(string)
  default     = {}
}