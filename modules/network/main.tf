terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

data "azurerm_client_config" "current" {}

locals {
  normalized_location   = replace(lower(var.location), " ", "")
  private_dns_zone_name = "privatelink.${local.normalized_location}.azmk8s.io"

  subnet_names = {
    for subnet_key, subnet in var.subnets : subnet_key => coalesce(try(subnet.name_override, null), subnet_key)
  }

  subnets_with_nsgs = {
    for subnet_key, subnet_name in local.subnet_names : subnet_key => subnet_name
    if subnet_name != "AzureBastionSubnet"
  }
}

resource "azurerm_network_security_group" "subnet" {
  for_each = local.subnets_with_nsgs

  name                = "${each.value}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Add subnets to the existing VNet (created by Bicep backend)
resource "azurerm_subnet" "subnet" {
  for_each = var.subnets

  name                 = local.subnet_names[each.key]
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [each.value.address_prefix]
}

resource "azurerm_subnet_network_security_group_association" "subnet" {
  for_each = local.subnets_with_nsgs

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.subnet[each.key].id
}

resource "azurerm_private_dns_zone" "aks" {
  name                = local.private_dns_zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks" {
  name                  = "${var.vnet_name}-aks-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${var.vnet_name}"
  registration_enabled  = false

  tags = var.tags
}
