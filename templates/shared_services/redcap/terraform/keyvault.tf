# NOTE: This keyvault exists because the core keyvault currently only
# supports access policies rather than RBAC. Therefore, the webapp identity
# would have to have complete access to the core keyvault secrets.

resource "azurerm_key_vault" "redcap" {
  name                          = "kv-redcap-${var.tre_id}"
  location                      = data.azurerm_resource_group.core.location
  resource_group_name           = data.azurerm_resource_group.core.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption   = false
  public_network_access_enabled = true
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  enable_rbac_authorization     = true
  sku_name                      = "standard"
  tags                          = local.tags

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }
}

resource "azurerm_role_assignment" "deployer_can_administrate_kv" {
  scope                = azurerm_key_vault.redcap.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-${azurerm_key_vault.redcap.name}"
  location            = data.azurerm_resource_group.core.location
  resource_group_name = data.azurerm_resource_group.core.name
  subnet_id           = data.azurerm_subnet.all["SharedSubnet"].id
  tags                = local.tags

  private_dns_zone_group {
    name                 = "private-dns-zone-group${azurerm_key_vault.redcap.name}"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.all["keyvault"].id]
  }

  private_service_connection {
    name                           = "private-service-connection-${azurerm_key_vault.redcap.name}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.redcap.id
    subresource_names              = ["Vault"]
  }
}

resource "null_resource" "wait_for_keyvault_pe" {
  triggers = {
    pe_keyvault_id = azurerm_private_endpoint.keyvault.id
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }

  depends_on = [
    azurerm_private_endpoint.keyvault
   ]
}
