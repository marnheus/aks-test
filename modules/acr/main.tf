module "registry" {
  source  = "Azure/avm-res-containerregistry-registry/azurerm"
  version = "~> 0.4"

  name                          = var.registry_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Premium"
  public_network_access_enabled = false
  tags                          = var.tags

  private_endpoints = {
    registry = {
      name                          = "${var.registry_name}-pe"
      subnet_resource_id            = var.private_endpoint_subnet_id
      private_dns_zone_resource_ids = toset(var.private_dns_zone_ids)
      tags                          = var.tags
    }
  }
}
