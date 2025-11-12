# Azure Private DNS Zone Terraform Module

This Terraform module creates Azure Private DNS Zones and virtual network links following Microsoft's [Azure Private DNS documentation](https://learn.microsoft.com/en-us/azure/dns/private-dns-privatednszone).

## Features

- ✅ **Multiple DNS Zones**: Create multiple private DNS zones in one module
- ✅ **Virtual Network Links**: Automatic linking to virtual networks
- ✅ **Registration & Resolution**: Support for both registration and resolution virtual networks
- ✅ **Azure Best Practices**: Follows Microsoft naming recommendations
- ✅ **Comprehensive Tagging**: Automatic and custom tags
- ✅ **Validation**: Input validation for all parameters
- ✅ **Lifecycle Management**: Configurable protection against deletion

## Private DNS Zone Requirements

Based on [Azure Private DNS documentation](https://learn.microsoft.com/en-us/azure/dns/private-dns-privatednszone), private DNS zones must:

- **Have valid domain names**: Must be actual domain names (e.g., `contoso.com`, `internal.company.com`)
- **Have at least 2 labels**: Single-label zones are not supported
- **Not use reserved names**: Cannot use Azure reserved zone names
- **Be linked to virtual networks**: Zones must be linked to virtual networks to be functional

## Usage

### Basic Usage

```hcl
module "private_dns_zones" {
  source = "gitlab.com/your-group/terraform-azure-private-dns-zone"
  
  private_dns_zones = {
    "contoso" = {
      zone_name = "contoso.com"
      virtual_network_links = [
        {
          name                = "vnet-link-1"
          virtual_network_id  = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/vnet-uks-proj-app-01"
          registration_enabled = true
        }
      ]
    }
    "internal" = {
      zone_name = "internal.contoso.com"
      virtual_network_links = [
        {
          name                = "vnet-link-1"
          virtual_network_id  = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/vnet-uks-proj-app-01"
          registration_enabled = false
        }
      ]
    }
  }
  
  resource_group_name = "rg-uks-proj-app-01"
  location = "UK South"
  project_name = "My Project"
  app_name = "My Application"
}
```

### Multiple Zones with Different Virtual Networks

```hcl
module "private_dns_zones" {
  source = "gitlab.com/your-group/terraform-azure-private-dns-zone"
  
  private_dns_zones = {
    "contoso" = {
      zone_name = "contoso.com"
      virtual_network_links = [
        {
          name                = "production-vnet"
          virtual_network_id  = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/vnet-prod"
          registration_enabled = true  # Registration virtual network
        },
        {
          name                = "staging-vnet"
          virtual_network_id  = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/vnet-staging"
          registration_enabled = false # Resolution virtual network
        }
      ]
    }
    "api" = {
      zone_name = "api.contoso.com"
      virtual_network_links = [
        {
          name                = "production-vnet"
          virtual_network_id  = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/vnet-prod"
          registration_enabled = true
        }
      ]
    }
  }
  
  resource_group_name = "rg-uks-proj-app-01"
  location = "UK South"
  project_name = "My Project"
  app_name = "My Application"
}
```

### Advanced Usage

```hcl
module "private_dns_zone" {
  source = "gitlab.com/your-group/terraform-azure-private-dns-zone"
  
  # Naming
  location_short = "uks"
  project_short = "proj"
  app_short = "app"
  suffix = "01"
  
  # Environment
  environment = "prod"
  prevent_destroy = true
  
  # Additional tags
  additional_tags = {
    "CostCenter" = "IT"
    "Owner" = "Platform Team"
    "Backup" = "Required"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| private_dns_zones | Map of private DNS zones to create with their virtual network links | `map(object)` | n/a | yes |
| resource_group_name | Name of the resource group where the private DNS zones will be created | `string` | n/a | yes |
| location | Azure region where the private DNS zones will be created | `string` | `"UK South"` | no |
| project_name | Full name of the project. Used for tagging and documentation | `string` | n/a | yes |
| app_name | Full name of the application. Used for tagging and documentation | `string` | n/a | yes |
| environment | Environment name (e.g., dev, staging, prod) | `string` | `"dev"` | no |
| prevent_destroy | Prevent accidental deletion of the private DNS zones | `bool` | `false` | no |
| additional_tags | Additional tags to apply to the private DNS zones | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| private_dns_zones | Map of private DNS zones created with their details |
| private_dns_zone_names | List of private DNS zone names |
| private_dns_zone_ids | List of private DNS zone IDs |
| virtual_network_links | Map of virtual network links created with their details |

## Examples

### Development Environment

```hcl
module "dev_private_dns_zone" {
  source = "gitlab.com/your-group/terraform-azure-private-dns-zone"
  
  resource_group_name = "rg-uks-ecomm-user-01"
  location = "UK South"
  location_short = "uks"
  project_name = "E-commerce Platform"
  project_short = "ecomm"
  app_name = "User Management"
  app_short = "user"
  suffix = "01"
  environment = "dev"
  
  additional_tags = {
    "CostCenter" = "Engineering"
    "Owner" = "Backend Team"
  }
}
```

### Production Environment

```hcl
module "prod_private_dns_zone" {
  source = "gitlab.com/your-group/terraform-azure-private-dns-zone"
  
  resource_group_name = "rg-uks-ecomm-user-01"
  location = "UK South"
  location_short = "uks"
  project_name = "E-commerce Platform"
  project_short = "ecomm"
  app_name = "User Management"
  app_short = "user"
  suffix = "01"
  environment = "prod"
  prevent_destroy = true
  
  additional_tags = {
    "CostCenter" = "Engineering"
    "Owner" = "Backend Team"
    "Backup" = "Required"
    "Monitoring" = "Critical"
  }
}
```

## Commit Message Usage

This project follows [Conventional Commits](https://www.conventionalcommits.org/) specification for commit messages. This enables automatic version bumping and changelog generation.

### Commit Message Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Supported Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **chore**: Changes to the build process or auxiliary tools

### Examples

```bash
# New feature
git commit -m "feat: add support for custom private DNS zone names"

# Bug fix
git commit -m "fix: resolve validation error for location parameter"

# Documentation
git commit -m "docs: update README with usage examples"

# Breaking change
git commit -m "feat!: change default naming convention format

BREAKING CHANGE: The default naming convention now includes environment prefix"
```

### Version Bumping

The GitLab CI pipeline automatically determines version bumps based on commit messages:

- **Major** (1.0.0 → 2.0.0): Breaking changes (`feat!`, `fix!`, or `BREAKING CHANGE:`)
- **Minor** (1.0.0 → 1.1.0): New features (`feat:`)
- **Patch** (1.0.0 → 1.0.1): Bug fixes and improvements (`fix:`, `perf:`, `refactor:`)

## .gitignore

This module includes a comprehensive `.gitignore` file that excludes:

- Terraform state files (`*.tfstate`, `*.tfstate.*`)
- Terraform variable files (`*.tfvars`, `*.tfvars.json`)
- Terraform directories (`.terraform/`, `.terraform.lock.hcl`)
- IDE files (`.vscode/`, `.idea/`)
- OS files (`.DS_Store`, `Thumbs.db`)
- Log files (`*.log`)
- Temporary files (`*.tmp`, `*.temp`)
- Environment files (`.env`)

## Terraform Docs Compatibility

This README is compatible with [terraform-docs](https://terraform-docs.io/) and will be automatically updated when you run:

```bash
terraform-docs markdown table --output-file README-scripts.md --output-mode inject .
```

The module structure follows terraform-docs conventions:
- Input and output tables are automatically generated
- Descriptions are extracted from variable and output comments
- Type information is automatically detected

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes following conventional commit format
4. Run `terraform fmt` and `terraform validate`
5. Commit your changes (`git commit -m 'feat: add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Support

For support and questions:
- Create an issue in the GitLab repository
- Contact the Platform Team
- Check the [Azure Private DNS Zone documentation](https://docs.microsoft.com/en-us/azure/dns/private-dns-overview)
