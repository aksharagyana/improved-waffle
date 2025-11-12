# Azure Subnet Module

This Terraform module creates an Azure Subnet with optional Network Security Group (NSG) and Route Table support. The module follows the same naming conventions and patterns as the storage-account-module for consistency.

## Features

- Creates a subnet within an existing virtual network
- Optional Network Security Group creation with custom rules
- Optional Route Table creation with custom routes
- Service endpoints configuration
- Subnet delegation support
- Consistent naming convention following project standards
- Comprehensive tagging strategy

## Usage

### Basic Usage

```hcl
module "subnet" {
  source = "./subnet-module"

  # Required variables
  vnet_id             = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Network/virtualNetworks/xxx"
  resource_group_name = "my-resource-group"
  address_prefixes    = ["10.0.1.0/24"]

  # Naming convention variables
  project_name    = "My Project"
  project_short   = "myprj"
  app_name        = "My Application"
  app_short       = "myapp"
  location_short  = "uks"
  suffix          = "01"

  # Optional: Create NSG
  create_nsg = true
  nsg_rules = [
    {
      name                       = "AllowSSH"
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Allow SSH access"
    }
  ]

  # Optional: Create Route Table
  create_route_table = true
  routes = [
    {
      name           = "DefaultRoute"
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "Internet"
    }
  ]

  # Service endpoints
  service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]

  tags = {
    Owner = "DevOps Team"
  }
}
```

### Advanced Usage with Delegation

```hcl
module "subnet" {
  source = "./subnet-module"

  vnet_id             = var.vnet_id
  resource_group_name = var.resource_group_name
  address_prefixes    = ["10.0.2.0/24"]

  project_name    = "Container Platform"
  project_short   = "cntr"
  app_name        = "AKS Cluster"
  app_short       = "aks"
  location_short  = "uks"
  suffix          = "01"

  # Create NSG with multiple rules
  create_nsg = true
  nsg_rules = [
    {
      name                       = "AllowHTTPS"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Allow HTTPS traffic"
    },
    {
      name                       = "DenyAllInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Deny all other inbound traffic"
    }
  ]

  # Service endpoints for AKS
  service_endpoints = [
    "Microsoft.ContainerRegistry",
    "Microsoft.Storage"
  ]

  # Delegation for AKS
  delegations = [
    {
      name = "aks-delegation"
      service_delegation = {
        name = "Microsoft.ContainerService/managedClusters"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/join/action"
        ]
      }
    }
  ]

  environment = "prod"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| subnet_name | Name of the subnet. If not provided, will be generated using naming convention | `string` | `null` | no |
| vnet_id | The ID of the virtual network where the subnet will be created | `string` | n/a | yes |
| resource_group_name | Name of the resource group where the subnet will be created | `string` | n/a | yes |
| location | Azure region where the subnet will be created | `string` | `"UK South"` | no |
| address_prefixes | The address prefixes to use for the subnet | `list(string)` | n/a | yes |
| project_name | Full name of the project. Used for tagging and documentation | `string` | n/a | yes |
| project_short | Short name of the project (3-5 characters). Used in resource naming | `string` | n/a | yes |
| app_name | Full name of the application. Used for tagging and documentation | `string` | n/a | yes |
| app_short | Short name of the application (3-5 characters). Used in resource naming | `string` | n/a | yes |
| location_short | Short name of the location (3 characters). Used in resource naming | `string` | `"uks"` | no |
| suffix | Suffix for resource naming (2 characters). Used to differentiate resources | `string` | `"01"` | no |
| create_nsg | Whether to create a Network Security Group for the subnet | `bool` | `true` | no |
| nsg_name | Name of the Network Security Group. If not provided, will be generated | `string` | `null` | no |
| nsg_rules | List of Network Security Group rules to create | `list(object)` | `[]` | no |
| create_route_table | Whether to create a Route Table for the subnet | `bool` | `false` | no |
| route_table_name | Name of the Route Table. If not provided, will be generated | `string` | `null` | no |
| routes | List of routes to create in the route table | `list(object)` | `[]` | no |
| service_endpoints | The list of Service endpoints to associate with the subnet | `list(string)` | `[]` | no |
| delegations | One or more delegation blocks | `list(object)` | `[]` | no |
| environment | Environment name (e.g., dev, staging, prod) | `string` | `"dev"` | no |
| additional_tags | Additional tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| subnet_id | The ID of the subnet |
| subnet_name | The name of the subnet |
| subnet_address_prefixes | The address prefixes for the subnet |
| subnet_virtual_network_name | The name of the virtual network in which the subnet is created |
| nsg_id | The ID of the Network Security Group |
| nsg_name | The name of the Network Security Group |
| nsg_location | The location of the Network Security Group |
| nsg_rules | The Network Security Group rules |
| route_table_id | The ID of the Route Table |
| route_table_name | The name of the Route Table |
| route_table_location | The location of the Route Table |
| routes | The routes in the Route Table |
| service_endpoints | The service endpoints associated with the subnet |
| delegations | The delegations associated with the subnet |
| common_tags | Common tags applied to all resources |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 3.0 |

