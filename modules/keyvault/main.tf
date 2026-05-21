module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.9"

  name                = var.vault_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = var.tenant_id
  tags                = var.tags

  legacy_access_policies_enabled = false
  public_network_access_enabled  = true

  network_acls = {
    bypass         = "AzureServices"
    default_action = "Allow"
  }

  private_endpoints = {
    primary = {
      name                          = "pe-${var.vault_name}"
      subnet_resource_id            = var.private_endpoint_subnet_id
      private_dns_zone_resource_ids = toset(var.private_dns_zone_ids)
      tags                          = var.tags
    }
  }
}
