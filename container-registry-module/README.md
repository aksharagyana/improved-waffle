# Azure Container Registry Module

This Terraform module creates an Azure Container Registry (ACR) with private endpoints only, following security best practices.

## Features

- **Private Access Only**: ACR is configured with private endpoints only, no public access
- **RBAC Only**: Admin access is disabled, access is managed through Azure RBAC
- **Security Hardened**: 
  - Public network access disabled
  - Anonymous pull disabled
  - Data endpoints disabled
  - No network bypass options
- **Encryption**: Optional encryption at rest
- **Retention Policy**: Configurable retention for untagged manifests
- **Zone Redundancy**: Optional zone redundancy for Premium SKU

## Usage

```hcl
module "acr" {
  source = "./container-registry-module"

  # Required variables
  resource_group_name = "rg-example"
  project_name        = "My Project"
  project_short       = "myprj"
  app_name           = "My Application"
  app_short          = "myapp"
  subnet_id          = "/subscriptions/.../subnets/example-subnet"
  private_dns_zone_id = "/subscriptions/.../privateDnsZones/privatelink.azurecr.io"

  # Optional variables
  acr_name           = "myacr"  # If not provided, will be auto-generated
  sku               = "Premium"
  location          = "UK South"
  environment       = "dev"
  zone_redundancy_enabled = false
}
```

## Prerequisites

- Subnet must exist and be provided via `subnet_id`
- Private DNS zone for `privatelink.azurecr.io` must exist and be provided via `private_dns_zone_id`
- Resource group must exist

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| acr_name | Name of the container registry. If not provided, will be generated using naming convention | `string` | `null` | no |
| resource_group_name | Name of the resource group where the container registry will be created | `string` | n/a | yes |
| location | Azure region where the container registry will be created | `string` | `"UK South"` | no |
| project_name | Full name of the project. Used for tagging and documentation | `string` | n/a | yes |
| project_short | Short name of the project (3-5 characters). Used in resource naming | `string` | n/a | yes |
| app_name | Full name of the application. Used for tagging and documentation | `string` | n/a | yes |
| app_short | Short name of the application (3-5 characters). Used in resource naming | `string` | n/a | yes |
| location_short | Short name of the location (3 characters). Used in resource naming | `string` | `"uks"` | no |
| suffix | Suffix for resource naming (2 characters). Used to differentiate resources | `string` | `"01"` | no |
| sku | The SKU name of the container registry. Valid values are Basic, Standard, Premium | `string` | `"Premium"` | no |
| subnet_id | The ID of the subnet from which private IP addresses will be allocated for this Private Endpoint | `string` | n/a | yes |
| private_dns_zone_id | The ID of the private DNS zone to register the private endpoints | `string` | n/a | yes |
| zone_redundancy_enabled | Whether zone redundancy is enabled for the container registry (Premium SKU only) | `bool` | `false` | no |
| environment | Environment name (e.g., dev, staging, prod) | `string` | `"dev"` | no |
| additional_tags | Additional tags to apply to the container registry | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| acr_id | The ID of the container registry |
| acr_name | The name of the container registry |
| acr_location | The location of the container registry |
| acr_login_server | The login server URL of the container registry |
| acr_sku | The SKU of the container registry |
| private_endpoint_id | The ID of the private endpoint |
| private_endpoint_name | The name of the private endpoint |
| private_endpoint_fqdn | The FQDN of the private endpoint |
| security_settings | Security settings for the container registry |
| common_tags | Common tags applied to all resources |

## Security Features

This module implements several security best practices:

1. **Private Access Only**: The ACR is configured with `public_network_access_enabled = false`
2. **RBAC Only**: Admin access is disabled (`admin_enabled = false`)
3. **No Anonymous Access**: Anonymous pull is disabled
4. **No Data Endpoints**: Data endpoints are disabled for private access only
5. **No Network Bypass**: Network rule bypass is set to "None"
6. **Encryption**: Optional encryption at rest
7. **Retention Policy**: Configurable retention for untagged manifests

## Naming Convention

If `acr_name` is not provided, the module will generate a name using the following pattern:
`acr{location_short}{project_short}{app_short}{suffix}`

Example: `acruksmyprjmyapp01`

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 3.0 |
