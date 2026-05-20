module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.9"

  name                = var.vault_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = var.tenant_id
  tags                = var.tags

  legacy_access_policies_enabled = false
  public_network_access_enabled  = false

  private_endpoints = {
    primary = {
      name                          = "pe-${var.vault_name}"
      subnet_resource_id            = var.private_endpoint_subnet_id
      private_dns_zone_resource_ids = toset(var.private_dns_zone_ids)
      tags                          = var.tags
    }
  }
}
