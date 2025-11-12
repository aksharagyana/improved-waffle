# Azure Storage Account Terraform Module

This Terraform module creates an Azure Storage Account with blob and queue storage capabilities, including private endpoints for secure access.

## Features

- **Storage Account**: Creates a StorageV2 account with configurable tier and replication
- **Blob Storage**: Optional blob container with configurable access policies and retention
- **Queue Storage**: Optional queue with logging and metrics configuration
- **Private Endpoints**: Secure access via private endpoints for blob and queue services
- **Private DNS Integration**: Automatic registration of private endpoints with private DNS zones
- **Network Security**: Configurable network access rules and security settings
- **Naming Convention**: Follows Azure naming conventions with auto-generated names
- **Comprehensive Tagging**: Automatic tagging with project, application, and environment information


### Provider Compatibility

The module is designed to work with AzureRM provider version 4.46.0+ and follows the latest Terraform best practices for Azure resource management.

## Usage

### Basic Usage

```hcl
module "storage_account" {
  source = "gitlab.com/your-group/terraform-azure-storage-account"
  
  # Storage account configuration
  resource_group_name = "rg-uks-proj-app-01"
  location = "UK South"
  
  # Project details
  project_name = "My Project"
  project_short = "proj"
  app_name = "My Application"
  app_short = "app"
  
  # Private endpoint configuration
  subnet_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."
  private_dns_zone_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
  
  # Storage services
  create_blob_container = true
  create_queue = true
}
```

### Advanced Usage with Custom Configuration

```hcl
module "storage_account" {
  source = "gitlab.com/your-group/terraform-azure-storage-account"
  
  # Storage account configuration
  storage_account_name = "mystorageaccount"  # Optional: will be auto-generated if not provided
  resource_group_name = "rg-uks-ecomm-user-01"
  location = "UK South"
  account_tier = "Standard"
  account_replication_type = "GRS"
  
  # Project details
  project_name = "E-commerce Platform"
  project_short = "ecomm"
  app_name = "User Management Service"
  app_short = "user"
  environment = "prod"
  
  # Private endpoint configuration
  subnet_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."
  private_dns_zone_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
  create_private_endpoints = true
  
  # Blob storage configuration
  create_blob_container = true
  blob_container_name = "user-data"
  blob_container_access_type = "private"
  blob_versioning_enabled = true
  blob_delete_retention_days = 30
  container_delete_retention_days = 30
  
  # Queue storage configuration
  create_queue = true
  queue_name = "user-tasks"
  queue_logging_retention_days = 30
  queue_hour_metrics_enabled = true
  queue_minute_metrics_enabled = true
  
  # Network security
  network_rules_default_action = "Deny"
  network_rules_bypass = ["Logging", "Metrics", "AzureServices"]
  public_network_access_enabled = false
  
  # Security settings
  enable_https_traffic_only = true
  min_tls_version = "TLS1_2"
  allow_nested_items_to_be_public = false
  infrastructure_encryption_enabled = true
  
  # Lifecycle
  prevent_destroy = true
  
  # Additional tags
  additional_tags = {
    "CostCenter" = "Engineering"
    "Owner" = "Backend Team"
    "Backup" = "Required"
    "Monitoring" = "Critical"
    "DataClassification" = "Internal"
  }
}
```

### Storage Account Naming Convention

If `storage_account_name` is not provided, the module will generate a name using the following convention:

```
st{location_short}{project_short}{app_short}{suffix}
```

Example: `stuksprojapp01`

Where:
- `st` = Storage account prefix
- `uks` = Location short (UK South)
- `proj` = Project short name
- `app` = Application short name
- `01` = Suffix

## Private Endpoint Requirements

This module creates private endpoints for blob and queue storage services. You need to provide:

1. **Subnet ID**: The subnet where private endpoints will be created
2. **Private DNS Zone ID**: The private DNS zone for `privatelink.blob.core.windows.net` and `privatelink.queue.core.windows.net`

### Required Private DNS Zones

You need to create the following private DNS zones in your tenant:

```hcl
# For blob storage private endpoints
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = "your-resource-group"
}

# For queue storage private endpoints
resource "azurerm_private_dns_zone" "queue" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = "your-resource-group"
}
```

## Git Commit Conventions

This module follows [Conventional Commits](https://www.conventionalcommits.org/) for automatic semantic versioning. The CI/CD pipeline automatically determines version bumps based on commit messages.

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
git commit -m "feat: add support for custom storage account names"

# Bug fix (patch version bump)
git commit -m "fix: resolve private endpoint DNS registration issue"

# Breaking change (major version bump)
git commit -m "feat!: change default storage account naming convention"

# Documentation update (no version bump)
git commit -m "docs: update README with usage examples"

# Performance improvement (patch version bump)
git commit -m "perf: optimize blob container creation"
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

1. Create a feature branch
2. Make your changes
3. Test with your Terraform modules
4. Submit a pull request

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_private_endpoint.blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_private_endpoint.queue](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_storage_account.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_container.blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [azurerm_storage_queue.queue](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_queue) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_replication_type"></a> [account\_replication\_type](#input\_account\_replication\_type) | Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS | `string` | `"LRS"` | no |
| <a name="input_account_tier"></a> [account\_tier](#input\_account\_tier) | Defines the Tier to use for this storage account. Valid options are Standard and Premium | `string` | `"Standard"` | no |
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Additional tags to apply to the storage account | `map(string)` | `{}` | no |
| <a name="input_allow_nested_items_to_be_public"></a> [allow\_nested\_items\_to\_be\_public](#input\_allow\_nested\_items\_to\_be\_public) | Allow or disallow nested items within this Storage Account to opt into being public | `bool` | `false` | no |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | Full name of the application. Used for tagging and documentation | `string` | n/a | yes |
| <a name="input_app_short"></a> [app\_short](#input\_app\_short) | Short name of the application (3-5 characters). Used in resource naming | `string` | n/a | yes |
| <a name="input_blob_change_feed_enabled"></a> [blob\_change\_feed\_enabled](#input\_blob\_change\_feed\_enabled) | Is the blob service properties for change feed events enabled | `bool` | `false` | no |
| <a name="input_blob_change_feed_retention_days"></a> [blob\_change\_feed\_retention\_days](#input\_blob\_change\_feed\_retention\_days) | The duration of change feed events retention in days | `number` | `0` | no |
| <a name="input_blob_container_access_type"></a> [blob\_container\_access\_type](#input\_blob\_container\_access\_type) | The access level configured for the container. Must be either 'blob', 'container' or 'private' | `string` | `"private"` | no |
| <a name="input_blob_container_name"></a> [blob\_container\_name](#input\_blob\_container\_name) | Name of the blob container to create | `string` | `"data"` | no |
| <a name="input_blob_delete_retention_days"></a> [blob\_delete\_retention\_days](#input\_blob\_delete\_retention\_days) | Specifies the number of days that the blob should be retained, between 1 and 365 days | `number` | `7` | no |
| <a name="input_blob_versioning_enabled"></a> [blob\_versioning\_enabled](#input\_blob\_versioning\_enabled) | Is versioning enabled for the blob service | `bool` | `false` | no |
| <a name="input_container_delete_retention_days"></a> [container\_delete\_retention\_days](#input\_container\_delete\_retention\_days) | Specifies the number of days that the container should be retained, between 1 and 365 days | `number` | `7` | no |
| <a name="input_create_blob_container"></a> [create\_blob\_container](#input\_create\_blob\_container) | Whether to create a blob container | `bool` | `true` | no |
| <a name="input_create_private_endpoints"></a> [create\_private\_endpoints](#input\_create\_private\_endpoints) | Whether to create private endpoints for blob and queue storage | `bool` | `true` | no |
| <a name="input_create_queue"></a> [create\_queue](#input\_create\_queue) | Whether to create a queue | `bool` | `true` | no |
| <a name="input_enable_https_traffic_only"></a> [enable\_https\_traffic\_only](#input\_enable\_https\_traffic\_only) | Boolean flag which forces HTTPS if enabled | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., dev, staging, prod) | `string` | `"dev"` | no |
| <a name="input_infrastructure_encryption_enabled"></a> [infrastructure\_encryption\_enabled](#input\_infrastructure\_encryption\_enabled) | Is infrastructure encryption enabled? Changing this forces a new resource to be created | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region where the storage account will be created | `string` | `"UK South"` | no |
| <a name="input_location_short"></a> [location\_short](#input\_location\_short) | Short name of the location (3 characters). Used in resource naming (e.g., 'uks' for 'UK South') | `string` | `"uks"` | no |
| <a name="input_min_tls_version"></a> [min\_tls\_version](#input\_min\_tls\_version) | The minimum supported TLS version for the storage account. Possible values are TLS1\_0, TLS1\_1, and TLS1\_2 | `string` | `"TLS1_2"` | no |
| <a name="input_network_rules_bypass"></a> [network\_rules\_bypass](#input\_network\_rules\_bypass) | Specifies whether traffic is bypassed for Logging/Metrics/AzureServices. Valid options are any combination of 'Logging', 'Metrics', 'AzureServices', or 'None' | `list(string)` | <pre>[<br/>  "Logging",<br/>  "Metrics",<br/>  "AzureServices"<br/>]</pre> | no |
| <a name="input_network_rules_default_action"></a> [network\_rules\_default\_action](#input\_network\_rules\_default\_action) | Specifies the default action of allow or deny when no other rules match. Valid options are 'Allow' or 'Deny' | `string` | `"Deny"` | no |
| <a name="input_network_rules_ip_rules"></a> [network\_rules\_ip\_rules](#input\_network\_rules\_ip\_rules) | List of public IP or IP ranges in CIDR Format. Only IPV4 addresses are allowed | `list(string)` | `[]` | no |
| <a name="input_network_rules_virtual_network_subnet_ids"></a> [network\_rules\_virtual\_network\_subnet\_ids](#input\_network\_rules\_virtual\_network\_subnet\_ids) | A list of virtual network subnet ids to to secure the storage account | `list(string)` | `[]` | no |
| <a name="input_private_dns_zone_id"></a> [private\_dns\_zone\_id](#input\_private\_dns\_zone\_id) | The ID of the private DNS zone to register the private endpoints | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Full name of the project. Used for tagging and documentation | `string` | n/a | yes |
| <a name="input_project_short"></a> [project\_short](#input\_project\_short) | Short name of the project (3-5 characters). Used in resource naming | `string` | n/a | yes |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether the public network access is enabled | `bool` | `false` | no |
| <a name="input_queue_hour_metrics_enabled"></a> [queue\_hour\_metrics\_enabled](#input\_queue\_hour\_metrics\_enabled) | Indicates whether hour metrics are enabled for the queue service | `bool` | `true` | no |
| <a name="input_queue_hour_metrics_include_apis"></a> [queue\_hour\_metrics\_include\_apis](#input\_queue\_hour\_metrics\_include\_apis) | Indicates whether metrics should generate summary statistics for called API operations | `bool` | `true` | no |
| <a name="input_queue_hour_metrics_retention_days"></a> [queue\_hour\_metrics\_retention\_days](#input\_queue\_hour\_metrics\_retention\_days) | Specifies the number of days that metrics will be retained | `number` | `7` | no |
| <a name="input_queue_logging_delete"></a> [queue\_logging\_delete](#input\_queue\_logging\_delete) | Indicates whether all delete requests should be logged | `bool` | `true` | no |
| <a name="input_queue_logging_read"></a> [queue\_logging\_read](#input\_queue\_logging\_read) | Indicates whether all read requests should be logged | `bool` | `true` | no |
| <a name="input_queue_logging_retention_days"></a> [queue\_logging\_retention\_days](#input\_queue\_logging\_retention\_days) | Specifies the number of days that logs will be retained | `number` | `7` | no |
| <a name="input_queue_logging_write"></a> [queue\_logging\_write](#input\_queue\_logging\_write) | Indicates whether all write requests should be logged | `bool` | `true` | no |
| <a name="input_queue_minute_metrics_enabled"></a> [queue\_minute\_metrics\_enabled](#input\_queue\_minute\_metrics\_enabled) | Indicates whether minute metrics are enabled for the queue service | `bool` | `false` | no |
| <a name="input_queue_minute_metrics_include_apis"></a> [queue\_minute\_metrics\_include\_apis](#input\_queue\_minute\_metrics\_include\_apis) | Indicates whether metrics should generate summary statistics for called API operations | `bool` | `true` | no |
| <a name="input_queue_minute_metrics_retention_days"></a> [queue\_minute\_metrics\_retention\_days](#input\_queue\_minute\_metrics\_retention\_days) | Specifies the number of days that metrics will be retained | `number` | `7` | no |
| <a name="input_queue_name"></a> [queue\_name](#input\_queue\_name) | Name of the queue to create | `string` | `"tasks"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where the storage account will be created | `string` | n/a | yes |
| <a name="input_shared_access_key_enabled"></a> [shared\_access\_key\_enabled](#input\_shared\_access\_key\_enabled) | Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key | `bool` | `true` | no |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | Name of the storage account. If not provided, will be generated using naming convention | `string` | `null` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | The ID of the subnet from which private IP addresses will be allocated for this Private Endpoint | `string` | n/a | yes |
| <a name="input_suffix"></a> [suffix](#input\_suffix) | Suffix for resource naming (2 characters). Used to differentiate resources | `string` | `"01"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_storage_account_id"></a> [storage\_account\_id](#output\_storage\_account\_id) | The ID of the storage account |
| <a name="output_storage_account_location"></a> [storage\_account\_location](#output\_storage\_account\_location) | The primary location of the storage account |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | The name of the storage account |
<!-- END_TF_DOCS -->