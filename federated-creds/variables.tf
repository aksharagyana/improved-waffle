# Variables for Federated Identity Credential Configuration

# AKS Cluster Information
variable "aks_cluster_name" {
  description = "Name of the existing AKS cluster"
  type        = string
}

variable "aks_resource_group_name" {
  description = "Resource group name where the AKS cluster is located"
  type        = string
}

# User Managed Identity Information
variable "umi_name" {
  description = "Name of the existing User Managed Identity"
  type        = string
}

variable "umi_resource_group_name" {
  description = "Resource group name where the User Managed Identity is located"
  type        = string
}

# Kubernetes Configuration
variable "kubernetes_namespace" {
  description = "Kubernetes namespace for the service account"
  type        = string
  default     = "default"
}

variable "kubernetes_service_account_name" {
  description = "Name of the Kubernetes service account"
  type        = string
  default     = "workload-identity-sa"
}

variable "create_namespace" {
  description = "Whether to create the Kubernetes namespace"
  type        = bool
  default     = true
}

# Federated Identity Credential Configuration
variable "federated_credential_name" {
  description = "Name of the federated identity credential"
  type        = string
  default     = null
}

variable "audience" {
  description = "Audience for the federated identity credential"
  type        = list(string)
  default     = ["api://AzureADTokenExchange"]
}

# Role Assignments (Optional)
variable "role_assignments" {
  description = "Map of role assignments for the User Managed Identity"
  type = map(object({
    scope                = string
    role_definition_name = string
  }))
  default = {}
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
