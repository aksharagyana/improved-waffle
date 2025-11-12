# Azure Private DNS Resolver Terraform Module

This Terraform module creates an Azure Private DNS Resolver with inbound endpoints for DNS resolution.

## Features

- **Private DNS Resolver**: Creates a Private DNS Resolver for hybrid DNS resolution
- **Inbound Endpoints**: Support for multiple inbound endpoints for DNS queries
- **Naming Convention**: Follows Azure naming conventions with auto-generated names
- **Comprehensive Tagging**: Automatic tagging with project, application, and environment information

## Important Notes

### Private DNS Resolver Requirements

This module creates a Private DNS Resolver that requires:

1. **Subnet ID**: The subnet where the Private DNS Resolver will be deployed
2. **Virtual Network**: The virtual network must exist and be accessible

### Network Requirements

- The subnet must be delegated to `Microsoft.Network/dnsResolvers`
- The subnet must have sufficient IP addresses available
- The virtual network must be in the same region as the Private DNS Resolver

### IP Allocation Methods

The module supports both dynamic and static IP allocation for inbound endpoints:

- **Dynamic**: Azure automatically assigns an available IP address from the subnet
- **Static**: You specify a specific IP address that must be available in the subnet

When using static allocation, you must provide the `private_ip_address` parameter.


## Usage

### Basic Usage

```hcl
module "private_dns_resolver" {
  source = "gitlab.com/your-group/terraform-azure-private-dns-resolver"
  
  # DNS Resolver configuration
  resource_group_name = "rg-uks-proj-app-01"
  location = "UK South"
  
  # Project details
  project_name = "My Project"
  project_short = "proj"
  app_name = "My Application"
  app_short = "app"
  
  # Private networking
  subnet_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."
  
  # Inbound endpoints
  inbound_endpoints = {
    "inbound-01" = {
      name = "inbound-endpoint-01"
      subnet_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."
      private_ip_allocation_method = "Dynamic"
    }
  }
}
```

### Static IP Allocation Example

```hcl
module "private_dns_resolver" {
  source = "gitlab.com/your-group/terraform-azure-private-dns-resolver"
  
  # Basic configuration
  resource_group_name = "rg-uks-proj-app-01"
  location = "UK South"
  
  # Project details
  project_name = "My Project"
  project_short = "proj"
  app_name = "My Application"
  app_short = "app"
  
  # Private networking
  subnet_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."
  
  # Inbound endpoint with static IP
  inbound_endpoints = {
    "inbound-01" = {
      name = "inbound-endpoint-01"
      subnet_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."
      private_ip_allocation_method = "Static"
      private_ip_address = "10.0.1.100"
    }
  }
}
```

### Advanced Usage with Multiple Endpoints

```hcl
module "private_dns_resolver" {
  source = "gitlab.com/your-group/terraform-azure-private-dns-resolver"
  
  # DNS Resolver configuration
  dns_resolver_name = "my-dns-resolver"
  resource_group_name = "rg-uks-ecomm-dns-01"
  location = "UK South"
  
  # Project details
  project_name = "E-commerce Platform"
  project_short = "ecomm"
  app_name = "DNS Resolution Service"
  app_short = "dns"
  environment = "prod"
  
  # Private networking
  subnet_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."
  
  # Multiple inbound endpoints
  inbound_endpoints = {
    "inbound-primary" = {
      name = "inbound-endpoint-primary"
      subnet_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."
      private_ip_allocation_method = "Static"
      private_ip_address = "10.0.1.10"
    }
    "inbound-secondary" = {
      name = "inbound-endpoint-secondary"
      subnet_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."
      private_ip_allocation_method = "Dynamic"
    }
  }
  
  # Lifecycle
  prevent_destroy = true
  
  # Additional tags
  additional_tags = {
    "CostCenter" = "Engineering"
    "Owner" = "Network Team"
    "Backup" = "Required"
    "Monitoring" = "Critical"
  }
}
```

### DNS Resolver Naming Convention

If `dns_resolver_name` is not provided, the module will generate a name using the following convention:

```
dns-{location_short}-{project_short}-{app_short}-{suffix}
```

Example: `dns-uksprojapp01`

Where:
- `dns` = DNS Resolver prefix
- `uks` = Location short (UK South)
- `proj` = Project short name
- `app` = Application short name
- `01` = Suffix

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| dns_resolver_name | Name of the Private DNS Resolver. If not provided, will be generated using naming convention | `string` | `null` | no |
| resource_group_name | Name of the resource group where the Private DNS Resolver will be created | `string` | n/a | yes |
| location | Azure region where the Private DNS Resolver will be created | `string` | `"UK South"` | no |
| project_name | Full name of the project. Used for tagging and documentation | `string` | n/a | yes |
| project_short | Short name of the project (3-5 characters). Used in resource naming | `string` | n/a | yes |
| app_name | Full name of the application. Used for tagging and documentation | `string` | n/a | yes |
| app_short | Short name of the application (3-5 characters). Used in resource naming | `string` | n/a | yes |
| location_short | Short name of the location (3 characters). Used in resource naming | `string` | `"uks"` | no |
| suffix | Suffix for resource naming (2 characters). Used to differentiate resources | `string` | `"01"` | no |
| subnet_id | The ID of the subnet where the Private DNS Resolver will be deployed | `string` | n/a | yes |
| inbound_endpoints | Map of inbound endpoints to create for the Private DNS Resolver | `map(object)` | `{}` | no |
| environment | Environment name (e.g., dev, staging, prod) | `string` | `"dev"` | no |
| prevent_destroy | Prevent accidental deletion of the Private DNS Resolver | `bool` | `false` | no |
| additional_tags | Additional tags to apply to the Private DNS Resolver | `map(string)` | `{}` | no |

### Inbound Endpoints Object

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the inbound endpoint | `string` | n/a | yes |
| subnet_id | The ID of the subnet for the inbound endpoint | `string` | n/a | yes |
| private_ip_allocation_method | Private IP allocation method (Dynamic or Static) | `string` | `"Dynamic"` | no |
| private_ip_address | Private IP address (required when allocation method is Static) | `string` | `null` | no |


## Outputs

| Name | Description |
|------|-------------|
| dns_resolver_id | The ID of the Private DNS Resolver |
| dns_resolver_name | The name of the Private DNS Resolver |
| dns_resolver_location | The location of the Private DNS Resolver |
| dns_resolver_virtual_network_id | The virtual network ID of the Private DNS Resolver |
| inbound_endpoints | The inbound endpoints of the Private DNS Resolver |
| inbound_endpoint_ids | The IDs of the inbound endpoints |
| inbound_endpoint_names | The names of the inbound endpoints |
| inbound_endpoint_ip_addresses | The IP addresses of the inbound endpoints |
| subnet_id | The subnet ID where the Private DNS Resolver is deployed |
| subnet_name | The name of the subnet where the Private DNS Resolver is deployed |
| subnet_virtual_network_name | The name of the virtual network containing the subnet |
| subnet_resource_group_name | The resource group name of the subnet |
| dns_resolver_fqdn | The FQDN of the Private DNS Resolver (if available) |
| common_tags | Common tags applied to all resources |
| inbound_endpoint_count | The number of inbound endpoints created |

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
git commit -m "feat: add support for multiple inbound endpoints"

# Bug fix (patch version bump)
git commit -m "fix: resolve subnet delegation issue"

# Breaking change (major version bump)
git commit -m "feat!: change default DNS forwarding configuration"

# Documentation update (no version bump)
git commit -m "docs: update README with usage examples"

# Performance improvement (patch version bump)
git commit -m "perf: optimize DNS resolver creation"
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

