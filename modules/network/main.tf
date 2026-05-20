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

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.4"

  name          = var.vnet_name
  location      = var.location
  parent_id     = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  address_space = var.address_space
  tags          = var.tags

  subnets = {
    for subnet_key, subnet in var.subnets : subnet_key => {
      name             = local.subnet_names[subnet_key]
      address_prefixes = [subnet.address_prefix]
      network_security_group = contains(keys(local.subnets_with_nsgs), subnet_key) ? {
        id = azurerm_network_security_group.subnet[subnet_key].id
      } : null
    }
  }
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
  virtual_network_id    = module.vnet.resource_id
  registration_enabled  = false

  tags = var.tags
}
