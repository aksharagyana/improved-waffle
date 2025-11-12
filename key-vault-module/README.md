# Azure Key Vault Module

This Terraform module creates an Azure Key Vault with private endpoints only, following security best practices.

## Features

- **Private Access Only**: Key Vault is configured with private endpoints only, no public access
- **RBAC Only**: Access policies are disabled, access is managed through Azure RBAC
- **Security Hardened**: 
  - Public network access disabled
  - Purge protection enabled by default
  - Soft delete retention configured
  - Network ACLs set to deny by default
- **Private Endpoints**: Key Vault accessible only through private endpoints

## Usage

```hcl
module "key_vault" {
  source = "./key-vault-module"

  # Required variables
  resource_group_name = "rg-example"
  project_name        = "My Project"
  project_short       = "myprj"
  app_name           = "My Application"
  app_short          = "myapp"
  subnet_id          = "/subscriptions/.../subnets/example-subnet"
  private_dns_zone_id = "/subscriptions/.../privateDnsZones/privatelink.vaultcore.azure.net"

  # Optional variables
  key_vault_name     = "mykv"  # If not provided, will be auto-generated
  sku_name          = "standard"
  location          = "UK South"
  environment       = "dev"
  purge_protection_enabled = true
  soft_delete_retention_days = 90
}
```

## Prerequisites

- Subnet must exist and be provided via `subnet_id`
- Private DNS zone for `privatelink.vaultcore.azure.net` must exist and be provided via `private_dns_zone_id`
- Resource group must exist

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| key_vault_name | Name of the key vault. If not provided, will be generated using naming convention | `string` | `null` | no |
| resource_group_name | Name of the resource group where the key vault will be created | `string` | n/a | yes |
| location | Azure region where the key vault will be created | `string` | `"UK South"` | no |
| project_name | Full name of the project. Used for tagging and documentation | `string` | n/a | yes |
| project_short | Short name of the project (3-5 characters). Used in resource naming | `string` | n/a | yes |
| app_name | Full name of the application. Used for tagging and documentation | `string` | n/a | yes |
| app_short | Short name of the application (3-5 characters). Used in resource naming | `string` | n/a | yes |
| location_short | Short name of the location (3 characters). Used in resource naming | `string` | `"uks"` | no |
| suffix | Suffix for resource naming (2 characters). Used to differentiate resources | `string` | `"01"` | no |
| sku_name | The Name of the SKU used for this Key Vault. Possible values are 'standard' and 'premium' | `string` | `"standard"` | no |
| subnet_id | The ID of the subnet from which private IP addresses will be allocated for this Private Endpoint | `string` | n/a | yes |
| private_dns_zone_id | The ID of the private DNS zone to register the private endpoints | `string` | n/a | yes |
| purge_protection_enabled | Is Purge Protection enabled for this Key Vault? | `bool` | `true` | no |
| soft_delete_retention_days | The number of days that items should be retained for once soft-deleted | `number` | `90` | no |
| environment | Environment name (e.g., dev, staging, prod) | `string` | `"dev"` | no |
| additional_tags | Additional tags to apply to the key vault | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| key_vault_id | The ID of the key vault |
| key_vault_name | The name of the key vault |
| key_vault_location | The location of the key vault |
| key_vault_uri | The URI of the key vault |
| key_vault_tenant_id | The tenant ID of the key vault |
| key_vault_sku_name | The SKU name of the key vault |
| private_endpoint_id | The ID of the private endpoint |
| private_endpoint_name | The name of the private endpoint |
| private_endpoint_fqdn | The FQDN of the private endpoint |
| security_settings | Security settings for the key vault |
| common_tags | Common tags applied to all resources |

## Security Features

This module implements several security best practices:

1. **Private Access Only**: The Key Vault is configured with `public_network_access_enabled = false`
2. **RBAC Only**: Access policies are disabled (`enable_rbac_authorization = true`)
3. **Purge Protection**: Enabled by default to prevent accidental deletion
4. **Soft Delete**: Configured with 90-day retention by default
5. **Network ACLs**: Set to deny by default with Azure services bypass
6. **Private Endpoints**: Key Vault accessible only through private endpoints

## Naming Convention

If `key_vault_name` is not provided, the module will generate a name using the following pattern:
`kv{location_short}{project_short}{app_short}{suffix}`

Example: `kvuksmyprjmyapp01`

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 3.0 |

## References

- [Azure Key Vault Terraform Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault)
- [Azure Key Vault Quickstart with Terraform](https://learn.microsoft.com/en-us/azure/key-vault/keys/quick-create-terraform?tabs=azure-cli)
