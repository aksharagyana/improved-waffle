# Azure Kubernetes Service (AKS) Terraform Module

This Terraform module creates an Azure Kubernetes Service (AKS) cluster with private networking, multiple node pools, and comprehensive configuration options.

## Features

- **Private AKS Cluster**: Creates a private AKS cluster with private networking
- **Kubenet Networking**: Uses kubenet networking plugin for private clusters
- **Private DNS Integration**: Automatic registration with private DNS zones
- **No Public IPs**: All nodes and clusters are private with no public IP addresses
- **Multiple Node Pools**: Support for default and additional node pools with different configurations
- **User Managed Identity**: Optional creation or use of existing User Assigned Identity
- **Comprehensive Security**: RBAC, Azure RBAC, and more
- **Auto Scaling**: Built-in cluster and node pool auto scaling
- **Naming Convention**: Follows Azure naming conventions with auto-generated names
- **Comprehensive Tagging**: Automatic tagging with project, application, and environment information

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | ~> 3.0 |

## Important Notes

### Private Cluster Requirements

This module creates a private AKS cluster with kubenet networking that requires:

1. **Subnet ID**: The subnet where the AKS cluster will be deployed
2. **Private DNS Zone ID**: The private DNS zone for `privatelink.{region}.azmk8s.io`
3. **Kubenet Networking**: Uses kubenet networking plugin (no Azure CNI)
4. **No Public IPs**: All nodes and clusters are private

### Required Private DNS Zones

You need to create the following private DNS zone in your subscription:

```hcl
# For AKS private cluster
resource "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.uksouth.azmk8s.io"  # Replace with your region
  resource_group_name = "your-resource-group"
}
```

### Kubenet Networking Considerations

According to [Microsoft documentation](https://learn.microsoft.com/en-us/azure/aks/configure-kubenet), kubenet networking:
- **Retirement Date**: March 31, 2028 (plan migration to Azure CNI overlay)
- **No Public IPs**: Nodes don't get public IP addresses
- **Route Tables**: Requires route tables for pod communication
- **Limitations**: Maximum 400 routes in UDR, no Windows node pools, no Azure network policies

### User Managed Identity

The module can either:
- **Create a new UMI**: Set `create_user_assigned_identity = true` (default)
- **Use existing UMI**: Set `create_user_assigned_identity = false` and provide `user_assigned_identity_ids`

## Usage

### Basic Usage

```hcl
module "aks_cluster" {
  source = "gitlab.com/your-group/terraform-azure-aks"
  
  # AKS cluster configuration
  resource_group_name = "rg-uks-proj-app-01"
  location = "UK South"
  
  # Project details
  project_name = "My Project"
  project_short = "proj"
  app_name = "My Application"
  app_short = "app"
  
  # Private networking
  subnet_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."
  private_dns_zone_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/privateDnsZones/privatelink.uksouth.azmk8s.io"
  
  # Default node pool
  default_node_pool = {
    name                = "default"
    vm_size             = "Standard_D2s_v3"
    node_count          = 1
    min_count           = 1
    max_count           = 10
    enable_auto_scaling = true
  }
}
```

### Advanced Usage with Multiple Node Pools

```hcl
module "aks_cluster" {
  source = "gitlab.com/your-group/terraform-azure-aks"
  
  # AKS cluster configuration
  aks_cluster_name = "my-aks-cluster"
  resource_group_name = "rg-uks-ecomm-user-01"
  location = "UK South"
  kubernetes_version = "1.28"
  
  # Project details
  project_name = "E-commerce Platform"
  project_short = "ecomm"
  app_name = "User Management Service"
  app_short = "user"
  environment = "prod"
  
  # Private networking
  subnet_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."
  private_dns_zone_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/privateDnsZones/privatelink.uksouth.azmk8s.io"
  
  # Default node pool
  default_node_pool = {
    name                = "system"
    vm_size             = "Standard_D2s_v3"
    node_count          = 2
    min_count           = 1
    max_count           = 10
    enable_auto_scaling = true
    os_disk_size_gb     = 50
    os_disk_type        = "Ephemeral"
    max_pods            = 30
    zones               = ["1", "2", "3"]
    node_labels = {
      "node-type" = "system"
      "environment" = "prod"
    }
  }
  
  # Additional node pools
  additional_node_pools = {
    "user-pool" = {
      name                = "user-pool"
      vm_size             = "Standard_D4s_v3"
      node_count          = 3
      min_count           = 1
      max_count           = 20
      enable_auto_scaling = true
      os_disk_size_gb     = 100
      max_pods            = 50
      zones               = ["1", "2", "3"]
      node_labels = {
        "node-type" = "user"
        "environment" = "prod"
      }
      node_taints = ["node-type=user:NoSchedule"]
    }
    "spot-pool" = {
      name                = "spot-pool"
      vm_size             = "Standard_D2s_v3"
      node_count          = 0
      min_count           = 0
      max_count           = 10
      enable_auto_scaling = true
      priority            = "Spot"
      eviction_policy     = "Delete"
      spot_max_price      = 0.5
      node_labels = {
        "node-type" = "spot"
        "environment" = "prod"
      }
      node_taints = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]
    }
  }
  
  # User Managed Identity
  create_user_assigned_identity = true
  
  # RBAC configuration
  rbac_enabled = true
  azure_rbac_enabled = true
  admin_group_object_ids = ["00000000-0000-0000-0000-000000000000"]
  
  # Security
  api_server_authorized_ip_ranges = ["203.0.113.0/24"]
  local_account_disabled = true
  sku_tier = "Paid"
  
  # Monitoring
  monitoring = {
    enabled = true
    log_analytics_workspace_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.OperationalInsights/workspaces/..."
  }
  
  # Addon profile
  addon_profile = {
    azure_policy = {
      enabled = true
    }
    oms_agent = {
      enabled = true
      log_analytics_workspace_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.OperationalInsights/workspaces/..."
    }
  }
  
  # Lifecycle
  prevent_destroy = true
  
  # Additional tags
  additional_tags = {
    "CostCenter" = "Engineering"
    "Owner" = "Platform Team"
    "Backup" = "Required"
    "Monitoring" = "Critical"
  }
}
```

### AKS Cluster Naming Convention

If `aks_cluster_name` is not provided, the module will generate a name using the following convention:

```
aks-{location_short}-{project_short}-{app_short}-{suffix}
```

Example: `aks-uksprojapp01`

Where:
- `aks` = AKS cluster prefix
- `uks` = Location short (UK South)
- `proj` = Project short name
- `app` = Application short name
- `01` = Suffix

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aks_cluster_name | Name of the AKS cluster. If not provided, will be generated using naming convention | `string` | `null` | no |
| resource_group_name | Name of the resource group where the AKS cluster will be created | `string` | n/a | yes |
| location | Azure region where the AKS cluster will be created | `string` | `"UK South"` | no |
| project_name | Full name of the project. Used for tagging and documentation | `string` | n/a | yes |
| project_short | Short name of the project (3-5 characters). Used in resource naming | `string` | n/a | yes |
| app_name | Full name of the application. Used for tagging and documentation | `string` | n/a | yes |
| app_short | Short name of the application (3-5 characters). Used in resource naming | `string` | n/a | yes |
| location_short | Short name of the location (3 characters). Used in resource naming | `string` | `"uks"` | no |
| suffix | Suffix for resource naming (2 characters). Used to differentiate resources | `string` | `"01"` | no |
| subnet_id | The ID of the subnet where the AKS cluster will be deployed | `string` | n/a | yes |
| private_dns_zone_id | The ID of the private DNS zone for the AKS cluster | `string` | n/a | yes |
| kubernetes_version | Version of Kubernetes to use for the AKS cluster | `string` | `"1.28"` | no |
| default_node_pool | Configuration for the default node pool | `object` | See variables.tf | no |
| additional_node_pools | Map of additional node pools to create | `map(object)` | `{}` | no |
| create_user_assigned_identity | Whether to create a new User Assigned Identity for the AKS cluster | `bool` | `true` | no |
| user_assigned_identity_ids | List of User Assigned Identity IDs to use for the AKS cluster | `list(string)` | `[]` | no |
| rbac_enabled | Whether to enable RBAC on the AKS cluster | `bool` | `true` | no |
| environment | Environment name (e.g., dev, staging, prod) | `string` | `"dev"` | no |
| prevent_destroy | Prevent accidental deletion of the AKS cluster | `bool` | `false` | no |
| additional_tags | Additional tags to apply to the AKS cluster | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| aks_cluster_id | The ID of the AKS cluster |
| aks_cluster_name | The name of the AKS cluster |
| aks_cluster_fqdn | The FQDN of the AKS cluster |
| aks_cluster_private_fqdn | The private FQDN of the AKS cluster |
| aks_cluster_kubernetes_version | The Kubernetes version of the AKS cluster |
| kube_config | The Kubernetes configuration for the AKS cluster (sensitive) |
| kube_config_client_key | The client key for the Kubernetes configuration (sensitive) |
| kube_config_client_certificate | The client certificate for the Kubernetes configuration (sensitive) |
| kube_config_cluster_ca_certificate | The cluster CA certificate for the Kubernetes configuration (sensitive) |
| kube_config_host | The host for the Kubernetes configuration (sensitive) |
| aks_cluster_identity | The identity of the AKS cluster |
| user_assigned_identity_id | The ID of the User Assigned Identity created for the AKS cluster |
| user_assigned_identity_principal_id | The Principal ID of the User Assigned Identity created for the AKS cluster |
| user_assigned_identity_client_id | The Client ID of the User Assigned Identity created for the AKS cluster |
| aks_cluster_network_profile | The network profile of the AKS cluster |
| default_node_pool | The default node pool of the AKS cluster |
| additional_node_pools | The additional node pools of the AKS cluster |
| rbac_enabled | Whether RBAC is enabled on the AKS cluster |
| addon_profile | The addon profile of the AKS cluster |
| local_account_disabled | Whether local accounts are disabled |
| sku_tier | The SKU tier of the AKS cluster |
| common_tags | Common tags applied to all resources |

## Examples

See the `examples/` directory for complete usage examples:

- [Basic Example](examples/basic/main.tf) - Minimal configuration
- [Advanced Example](examples/advanced/main.tf) - Full configuration with all options

## Git Commit Conventions

This module follows [Conventional Commits 1.0.0 specification](https://www.conventionalcommits.org/en/v1.0.0/) for automatic semantic versioning. The CI/CD pipeline automatically determines version bumps based on commit messages.

### Commit Message Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Supported Types

| Type | Description | Version Bump |
|------|-------------|--------------|
| `feat` | A new feature | Minor (0.1.0) |
| `fix` | A bug fix | Patch (0.0.1) |
| `perf` | A performance improvement | Patch (0.0.1) |
| `refactor` | Code refactoring | Patch (0.0.1) |
| `docs` | Documentation changes | No version bump |
| `style` | Code style changes (formatting, etc.) | No version bump |
| `test` | Adding or updating tests | No version bump |
| `chore` | Maintenance tasks | No version bump |

### Breaking Changes

To indicate a breaking change, add `!` after the type/scope or include `BREAKING CHANGE:` in the footer:

```bash
# Using ! after type
feat!: remove deprecated parameter

# Using BREAKING CHANGE in footer
feat: add new parameter

BREAKING CHANGE: The old parameter has been removed
```

### Examples

```bash
# New feature (minor version bump)
git commit -m "feat: add support for multiple node pools"

# Bug fix (patch version bump)
git commit -m "fix: resolve private DNS zone registration issue"

# Breaking change (major version bump)
git commit -m "feat!: change default node pool configuration"

# Documentation update (no version bump)
git commit -m "docs: update README with usage examples"

# Performance improvement (patch version bump)
git commit -m "perf: optimize AKS cluster creation"
```

### Version Bump Logic

The CI/CD pipeline automatically determines version bumps:

1. **Major (1.0.0)**: Breaking changes (`feat!`, `fix!`, `perf!`, `refactor!` or `BREAKING CHANGE:`)
2. **Minor (0.1.0)**: New features (`feat:`)
3. **Patch (0.0.1)**: Bug fixes, performance improvements, refactoring (`fix:`, `perf:`, `refactor:`)
4. **No bump**: Documentation, style, tests, chores (`docs:`, `style:`, `test:`, `chore:`)

### Pipeline Behavior

- **Feature branches**: Validation and documentation generation
- **Main branch**: Manual trigger required for publishing
- **Tags**: Automatic version detection and registry publishing
- **Documentation**: Auto-generated and committed to feature branches

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes following the commit conventions
4. Add tests if applicable
5. Submit a pull request

## License

This module is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Support

For support and questions, please open an issue in the GitLab repository.
