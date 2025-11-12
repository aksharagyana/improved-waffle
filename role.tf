resource "azurerm_role_definition" "custom_aks_pgsql_acr_storage_log" {
  name        = "AKS-Postgres-ACR-Storage-LogAnalytics-KeyVault-Operator"
  scope       = data.azurerm_resource_group.target.id
  description = "Can provision AKS, PostgreSQL Flexible Server, ACR, Storage (Blob+Queue+Containers), Event Grid Topics, Log Analytics Workspace, and Key Vault with private endpoints."

  permissions {
    actions = [
      # AKS
      "Microsoft.ContainerService/managedClusters/*",

      # PostgreSQL Flexible Server
      "Microsoft.DBforPostgreSQL/flexibleServers/*",
      "Microsoft.DBforPostgreSQL/flexibleServers/firewallRules/*",
      "Microsoft.DBforPostgreSQL/flexibleServers/configurations/*",

      # ACR
      "Microsoft.ContainerRegistry/registries/*",

      # Storage
      "Microsoft.Storage/storageAccounts/*",
      "Microsoft.Storage/storageAccounts/blobServices/*",
      "Microsoft.Storage/storageAccounts/queueServices/*",
      "Microsoft.Storage/storageAccounts/queueServices/queues/*",
      "Microsoft.Storage/storageAccounts/blobServices/containers/*",

      # Log Analytics
      "Microsoft.OperationalInsights/workspaces/*",

      # Event Grid
      "Microsoft.EventGrid/topics/*",
      "Microsoft.EventGrid/domains/*",
      "Microsoft.EventGrid/systemTopics/*",

      # Key Vault
      "Microsoft.KeyVault/vaults/*",
      "Microsoft.KeyVault/vaults/secrets/*",
      "Microsoft.KeyVault/vaults/keys/*",


      # Supporting
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/privateEndpoints/*",
      "Microsoft.Network/privateDnsZones/*",
      "Microsoft.Insights/diagnosticSettings/*",
      "Microsoft.ManagedIdentity/userAssignedIdentities/*"
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_resource_group.target.id
  ]
}


resource "azurerm_role_assignment" "spn_assignment" {
  scope              = data.azurerm_resource_group.target.id
  role_definition_id = azurerm_role_definition.custom_aks_pgsql_acr_storage_log.role_definition_resource_id
  principal_id       = azuread_service_principal.spn.object_id
}



resource "azurerm_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations-uksouth"
  scope                = azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/6e18b1f5-2b76-4f8d-9e07-1b4c3e88c707"
  display_name         = "Allow only UK South"
  description          = "This policy ensures that resources can only be deployed in UK South."

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = ["uksouth"]
    }
  })
}
