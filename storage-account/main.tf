# Local values for common tags
locals {
  # Common tags applied to all resources
  common_tags = merge(
    {
      "Project"      = var.project_name
      "Application"  = var.app_name
      "Environment"  = var.environment
      "ManagedBy"    = "Terraform"
      "CreatedDate"  = formatdate("YYYY-MM-DD", timestamp())
      "LastModified" = formatdate("YYYY-MM-DD", timestamp())
    },
    var.additional_tags
  )
}

# Create the storage account
resource "azurerm_storage_account" "main" {
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = "StorageV2"

  # Enable blob and queue services
  blob_properties {
    versioning_enabled            = var.blob_versioning_enabled
    change_feed_enabled           = var.blob_change_feed_enabled
    change_feed_retention_in_days = var.blob_change_feed_retention_days

    delete_retention_policy {
      days = var.blob_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.container_delete_retention_days
    }
  }

  # Network access rules
  network_rules {
    default_action             = var.network_rules_default_action
    bypass                     = var.network_rules_bypass
    ip_rules                   = var.network_rules_ip_rules
    virtual_network_subnet_ids = var.network_rules_virtual_network_subnet_ids
  }

  # Security settings
  https_traffic_only_enabled      = var.enable_https_traffic_only
  min_tls_version                 = var.min_tls_version
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  shared_access_key_enabled       = var.shared_access_key_enabled
  public_network_access_enabled   = var.public_network_access_enabled

  # Encryption settings
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled

  tags = local.common_tags

  lifecycle {
    # Ignore changes to tags that are managed by external processes
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"]
    ]
  }
}

# Create blob container
resource "azurerm_storage_container" "blob" {
  count                 = var.create_blob_container ? 1 : 0
  name                  = var.blob_container_name
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = var.blob_container_access_type
}

# Create queue
resource "azurerm_storage_queue" "queue" {
  count                = var.create_queue ? 1 : 0
  name                 = var.queue_name
  storage_account_name = azurerm_storage_account.main.name
}

# Create private endpoint for blob storage
resource "azurerm_private_endpoint" "blob" {
  count               = var.create_private_endpoints ? 1 : 0
  name                = "${local.storage_account_name}-blob-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${local.storage_account_name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${local.storage_account_name}-blob-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"]
    ]
  }
}

# Create private endpoint for queue storage
resource "azurerm_private_endpoint" "queue" {
  count               = var.create_private_endpoints ? 1 : 0
  name                = "${local.storage_account_name}-queue-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${local.storage_account_name}-queue-psc"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${local.storage_account_name}-queue-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
      tags["LastModified"]
    ]
  }
}

# Local values for storage account naming
locals {
  # Generate storage account name if not provided
  storage_account_name = var.storage_account_name != null ? var.storage_account_name : "st${replace(var.location_short, "-", "")}${var.project_short}${var.app_short}${var.suffix}"
}
