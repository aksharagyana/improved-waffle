# Azure Database for PostgreSQL - Flexible Server Terraform Module

This Terraform module creates an Azure Database for PostgreSQL - Flexible Server with private networking, high availability, and comprehensive configuration options.

## Features

- **Private PostgreSQL Server**: Creates a private PostgreSQL Flexible Server with no public access
- **Private DNS Integration**: Automatic registration with private DNS zones
- **High Availability**: Support for zone-redundant and same-zone high availability
- **User Managed Identity**: Optional creation or use of existing User Assigned Identity
- **Comprehensive Security**: Active Directory authentication, customer managed keys, and more
- **Flexible Storage**: Configurable storage size and backup retention
- **Multiple Databases**: Support for creating multiple databases on the server
- **Firewall Rules**: Configurable firewall rules for secure access
- **PostgreSQL Configurations**: Custom PostgreSQL parameter configurations
- **Naming Convention**: Follows Azure naming conventions with auto-generated names
- **Comprehensive Tagging**: Automatic tagging with project, application, and environment information

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | ~> 3.0 |

## Important Notes

### Private Server Requirements

This module creates a private PostgreSQL Flexible Server that requires:

1. **Subnet ID**: The subnet where the PostgreSQL server will be deployed
2. **Private DNS Zone ID**: The private DNS zone for `privatelink.postgres.database.azure.com`

### Required Private DNS Zones

You need to create the following private DNS zone in your subscription:

```hcl
# For PostgreSQL Flexible Server
resource "azurerm_private_dns_zone" "postgresql" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = "your-resource-group"
}
```

### User Managed Identity

The module can either:
- **Create a new UMI**: Set `create_user_assigned_identity = true` (default)
- **Use existing UMI**: Set `create_user_assigned_identity = false` and provide `user_assigned_identity_ids`

## Usage

### Basic Usage

```hcl
module "postgresql_server" {
  source = "gitlab.com/your-group/terraform-azure-postgresql-flexible-server"
  
  # PostgreSQL server configuration
  resource_group_name = "rg-uks-proj-app-01"
  location = "UK South"
  
  # Project details
  project_name = "My Project"
  project_short = "proj"
  app_name = "My Application"
  app_short = "app"
  
  # Private networking
  subnet_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."
  private_dns_zone_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/privateDnsZones/privatelink.postgres.database.azure.com"
  
  # Administrator credentials
  administrator_login = "psqladmin"
  administrator_password = "YourSecurePassword123!"
  
  # Storage configuration
  storage_mb = 32768
  backup_retention_days = 7
  
  # User Managed Identity
  create_user_assigned_identity = true
}
```

### Advanced Usage with High Availability

```hcl
module "postgresql_server" {
  source = "gitlab.com/your-group/terraform-azure-postgresql-flexible-server"
  
  # PostgreSQL server configuration
  postgresql_server_name = "my-postgresql-server"
  resource_group_name = "rg-uks-ecomm-user-01"
  location = "UK South"
  postgresql_version = "15"
  
  # Project details
  project_name = "E-commerce Platform"
  project_short = "ecomm"
  app_name = "User Management Service"
  app_short = "user"
  environment = "prod"
  
  # Private networking
  subnet_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."
  private_dns_zone_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/privateDnsZones/privatelink.postgres.database.azure.com"
  
  # Administrator credentials
  administrator_login = "psqladmin"
  administrator_password = "YourSecurePassword123!"
  
  # Storage configuration
  storage_mb = 131072  # 128 GB
  backup_retention_days = 30
  geo_redundant_backup_enabled = true
  
  # High availability
  high_availability = {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }
  
  # SKU configuration
  sku_name = "GP_Standard_D4s_v3"
  
  # Authentication
  authentication = {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
  }
  
  # Customer managed key
  customer_managed_key = {
    key_vault_key_id                  = "/subscriptions/.../providers/Microsoft.KeyVault/vaults/.../keys/..."
    primary_user_assigned_identity_id = "/subscriptions/.../providers/Microsoft.ManagedIdentity/userAssignedIdentities/..."
  }
  
  # PostgreSQL configurations
  postgresql_configurations = {
    "shared_preload_libraries" = "pg_stat_statements"
    "log_statement"            = "all"
    "log_min_duration_statement" = "1000"
  }
  
  # Firewall rules
  firewall_rules = {
    "allow-azure-services" = {
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    }
  }
  
  # Databases
  databases = {
    "app_database" = {
      collation = "en_US.utf8"
      charset   = "utf8"
    }
    "analytics_database" = {
      collation = "en_US.utf8"
      charset   = "utf8"
    }
  }
  
  # Active Directory administrator
  active_directory_administrator = {
    tenant_id   = "00000000-0000-0000-0000-000000000000"
    object_id   = "11111111-1111-1111-1111-111111111111"
    identity_id = "/subscriptions/.../providers/Microsoft.ManagedIdentity/userAssignedIdentities/..."
    login       = "azure_ad_admin"
  }
  
  # User Managed Identity
  create_user_assigned_identity = true
  
  # Lifecycle
  prevent_destroy = true
  
  # Additional tags
  additional_tags = {
    "CostCenter" = "Engineering"
    "Owner" = "Database Team"
    "Backup" = "Required"
    "Monitoring" = "Critical"
  }
}
```

### PostgreSQL Server Naming Convention

If `postgresql_server_name` is not provided, the module will generate a name using the following convention:

```
psql-{location_short}-{project_short}-{app_short}-{suffix}
```

Example: `psql-uksprojapp01`

Where:
- `psql` = PostgreSQL server prefix
- `uks` = Location short (UK South)
- `proj` = Project short name
- `app` = Application short name
- `01` = Suffix

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| postgresql_server_name | Name of the PostgreSQL server. If not provided, will be generated using naming convention | `string` | `null` | no |
| resource_group_name | Name of the resource group where the PostgreSQL server will be created | `string` | n/a | yes |
| location | Azure region where the PostgreSQL server will be created | `string` | `"UK South"` | no |
| project_name | Full name of the project. Used for tagging and documentation | `string` | n/a | yes |
| project_short | Short name of the project (3-5 characters). Used in resource naming | `string` | n/a | yes |
| app_name | Full name of the application. Used for tagging and documentation | `string` | n/a | yes |
| app_short | Short name of the application (3-5 characters). Used in resource naming | `string` | n/a | yes |
| location_short | Short name of the location (3 characters). Used in resource naming | `string` | `"uks"` | no |
| suffix | Suffix for resource naming (2 characters). Used to differentiate resources | `string` | `"01"` | no |
| subnet_id | The ID of the subnet where the PostgreSQL server will be deployed | `string` | n/a | yes |
| private_dns_zone_id | The ID of the private DNS zone for the PostgreSQL server | `string` | n/a | yes |
| postgresql_version | Version of PostgreSQL to use | `string` | `"15"` | no |
| administrator_login | The administrator login name for the PostgreSQL server | `string` | `"psqladmin"` | no |
| administrator_password | The administrator password for the PostgreSQL server | `string` | n/a | yes |
| storage_mb | The max storage allowed for the PostgreSQL server in MB | `number` | `32768` | no |
| backup_retention_days | The backup retention days for the PostgreSQL server | `number` | `7` | no |
| geo_redundant_backup_enabled | Whether geo-redundant backup is enabled | `bool` | `false` | no |
| high_availability | High availability configuration for the PostgreSQL server | `object` | See variables.tf | no |
| sku_name | The SKU name for the PostgreSQL server | `string` | `"GP_Standard_D2s_v3"` | no |
| create_user_assigned_identity | Whether to create a new User Assigned Identity for the PostgreSQL server | `bool` | `true` | no |
| user_assigned_identity_ids | List of User Assigned Identity IDs to use for the PostgreSQL server | `list(string)` | `[]` | no |
| postgresql_configurations | Map of PostgreSQL configurations to set on the server | `map(string)` | `{}` | no |
| firewall_rules | Map of firewall rules to create for the PostgreSQL server | `map(object)` | `{}` | no |
| databases | Map of databases to create on the PostgreSQL server | `map(object)` | `{}` | no |
| environment | Environment name (e.g., dev, staging, prod) | `string` | `"dev"` | no |
| prevent_destroy | Prevent accidental deletion of the PostgreSQL server | `bool` | `false` | no |
| additional_tags | Additional tags to apply to the PostgreSQL server | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| postgresql_server_id | The ID of the PostgreSQL server |
| postgresql_server_name | The name of the PostgreSQL server |
| postgresql_server_fqdn | The FQDN of the PostgreSQL server |
| postgresql_server_version | The version of the PostgreSQL server |
| postgresql_server_zone | The availability zone of the PostgreSQL server |
| postgresql_server_public_network_access_enabled | Whether public network access is enabled |
| postgresql_server_delegated_subnet_id | The delegated subnet ID of the PostgreSQL server |
| postgresql_server_private_dns_zone_id | The private DNS zone ID of the PostgreSQL server |
| postgresql_server_storage_mb | The storage size in MB of the PostgreSQL server |
| postgresql_server_backup_retention_days | The backup retention days of the PostgreSQL server |
| postgresql_server_geo_redundant_backup_enabled | Whether geo-redundant backup is enabled |
| postgresql_server_high_availability | The high availability configuration of the PostgreSQL server |
| postgresql_server_maintenance_window | The maintenance window of the PostgreSQL server |
| postgresql_server_identity | The identity of the PostgreSQL server |
| user_assigned_identity_id | The ID of the User Assigned Identity created for the PostgreSQL server |
| user_assigned_identity_principal_id | The Principal ID of the User Assigned Identity created for the PostgreSQL server |
| user_assigned_identity_client_id | The Client ID of the User Assigned Identity created for the PostgreSQL server |
| postgresql_server_sku_name | The SKU name of the PostgreSQL server |
| postgresql_server_authentication | The authentication configuration of the PostgreSQL server |
| postgresql_server_customer_managed_key | The customer managed key configuration of the PostgreSQL server |
| postgresql_server_replication_role | The replication role of the PostgreSQL server |
| postgresql_configurations | The PostgreSQL configurations set on the server |
| postgresql_firewall_rules | The firewall rules of the PostgreSQL server |
| postgresql_databases | The databases created on the PostgreSQL server |
| postgresql_active_directory_administrator | The Active Directory administrator of the PostgreSQL server |
| postgresql_connection_string | The connection string for the PostgreSQL server (sensitive) |
| postgresql_host | The hostname of the PostgreSQL server |
| postgresql_port | The port of the PostgreSQL server |
| postgresql_username | The administrator username of the PostgreSQL server |
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
git commit -m "feat: add support for high availability configuration"

# Bug fix (patch version bump)
git commit -m "fix: resolve private DNS zone registration issue"

# Breaking change (major version bump)
git commit -m "feat!: change default storage configuration"

# Documentation update (no version bump)
git commit -m "docs: update README with usage examples"

# Performance improvement (patch version bump)
git commit -m "perf: optimize PostgreSQL server creation"
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
