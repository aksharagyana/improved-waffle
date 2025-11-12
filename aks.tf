# Default node pool (already in the cluster)
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "private-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "privateaks"

  default_node_pool {
    name                = "default"
    node_count          = 2
    vm_size             = "Standard_DS2_v2"
    vnet_subnet_id      = azurerm_subnet.aks_subnet.id
    only_critical_addons_enabled = true   # Good practice for system pods
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    network_policy    = "azure"
    service_cidr      = "10.10.2.0/24"
    dns_service_ip    = "10.10.2.10"
  }

  private_cluster_enabled = true

  role_based_access_control {
    enabled = true
  }

  tags = {
    Environment = "Private-AKS"
  }
}

# Extra Node Pool (Linux general purpose)
resource "azurerm_kubernetes_cluster_node_pool" "linuxpool" {
  name                  = "linuxgp"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_DS3_v2"
  node_count            = 3
  vnet_subnet_id        = azurerm_subnet.aks_subnet.id
  mode                  = "User"     # Important: User pools are for workloads
  os_type               = "Linux"
  os_disk_size_gb       = 100
  node_labels = {
    "workload" = "general"
  }
}

# Extra Node Pool (Windows workloads)
resource "azurerm_kubernetes_cluster_node_pool" "windowspool" {
  name                  = "winpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_D4s_v3"
  node_count            = 2
  vnet_subnet_id        = azurerm_subnet.aks_subnet.id
  mode                  = "User"
  os_type               = "Windows"
  node_labels = {
    "workload" = "windows"
  }
}



resource "azurerm_private_endpoint" "blob_pe" {
  name                = "pe-blob"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "blobConnection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_dns.id]
  }
}

resource "azurerm_private_endpoint" "queue_pe" {
  name                = "pe-queue"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "queueConnection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "queue-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.queue_dns.id]
  }
}
