data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

// VNet is created by the Bicep backend; reference it via data source
data "azurerm_virtual_network" "backend" {
  name                = var.backend_vnet_name
  resource_group_name = var.backend_resource_group
}

// Blob private DNS zone is created by Bicep backend
data "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.backend_resource_group
}

module "network" {
  source = "./modules/network"

  resource_group_name = var.backend_resource_group
  location            = azurerm_resource_group.main.location
  vnet_name           = var.backend_vnet_name
  address_space       = var.vnet_address_space
  existing_vnet       = true
  subnets = {
    for subnet_name, cidr in local.subnets : subnet_name => merge(
      {
        address_prefix = cidr
      },
      subnet_name == "bastion" ? {
        name_override = "AzureBastionSubnet"
      } : {}
    )
  }
  tags = var.tags
}

// NAT Gateway is created by the Bicep backend; associate it with Terraform-managed subnets
data "azurerm_nat_gateway" "backend" {
  name                = "natgw-aksbackend-runner"
  resource_group_name = var.backend_resource_group
}

import {
  to = azurerm_subnet_nat_gateway_association.aks
  id = "/subscriptions/bff83385-09ed-4da6-a3e9-d299d9763f11/resourceGroups/rg-aks-backend-westeurope/providers/Microsoft.Network/virtualNetworks/vnet-aksbackend/subnets/aks"
}

resource "azurerm_subnet_nat_gateway_association" "aks" {
  subnet_id      = module.network.subnet_ids["aks"]
  nat_gateway_id = data.azurerm_nat_gateway.backend.id
}

resource "azurerm_subnet_nat_gateway_association" "jumpbox" {
  subnet_id      = module.network.subnet_ids["jumpbox"]
  nat_gateway_id = data.azurerm_nat_gateway.backend.id
}

module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  workspace_name      = "${local.name_prefix}-law-${local.resource_suffix}"
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "private_link" {
  for_each = {
    keyvault = "privatelink.vaultcore.azure.net"
    acr      = "privatelink.azurecr.io"
  }

  name                = each.value
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_link" {
  for_each = azurerm_private_dns_zone.private_link

  name                  = "${local.name_prefix}-${each.key}-dns-link-${local.resource_suffix}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = data.azurerm_virtual_network.backend.id
  registration_enabled  = false
  tags                  = var.tags
}

module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  vault_name                 = "${local.name_prefix}-kv-${local.resource_suffix}"
  private_endpoint_subnet_id = module.network.subnet_ids["private_endpoint"]
  private_dns_zone_ids       = [azurerm_private_dns_zone.private_link["keyvault"].id]
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  tags                       = var.tags
}

module "storage" {
  source = "./modules/storage"

  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  storage_account_name       = substr(lower(replace("${local.name_prefix}storage${local.resource_suffix}", "-", "")), 0, 24)
  private_endpoint_subnet_id = module.network.subnet_ids["private_endpoint"]
  private_dns_zone_ids       = [data.azurerm_private_dns_zone.blob.id]
  tags                       = var.tags
}

module "acr" {
  source = "./modules/acr"

  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  registry_name              = lower(replace("${local.name_prefix}acr${local.resource_suffix}", "-", ""))
  private_endpoint_subnet_id = module.network.subnet_ids["private_endpoint"]
  private_dns_zone_ids       = [azurerm_private_dns_zone.private_link["acr"].id]
  tags                       = var.tags
}

module "bastion" {
  source = "./modules/bastion"

  resource_group_name = azurerm_resource_group.main.name
  resource_group_id   = azurerm_resource_group.main.id
  location            = azurerm_resource_group.main.location
  bastion_name        = "${local.name_prefix}-bastion-${local.resource_suffix}"
  subnet_id           = module.network.subnet_ids["bastion"]
  tags                = var.tags
}

module "jumpbox" {
  source = "./modules/jumpbox"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = module.network.subnet_ids["jumpbox"]
  name_prefix         = "${local.name_prefix}-${local.resource_suffix}"
  admin_username      = random_pet.jumpbox_admin_username.id
  admin_password      = random_password.jumpbox_windows_password.result
  tags                = var.tags
}

// GitHub runner is deployed by the Bicep backend (see backend/main.bicep)

module "aks" {
  source = "./modules/aks"

  resource_group_name        = azurerm_resource_group.main.name
  resource_group_id          = azurerm_resource_group.main.id
  location                   = azurerm_resource_group.main.location
  cluster_name               = "${local.name_prefix}-aks-${local.resource_suffix}"
  kubernetes_version         = var.kubernetes_version
  subnet_id                  = module.network.subnet_ids["aks"]
  log_analytics_workspace_id = module.monitoring.workspace_id
  private_dns_zone_id        = module.network.private_dns_zone_id
  acr_id                     = module.acr.registry_id
  tags                       = var.tags

  depends_on = [azurerm_subnet_nat_gateway_association.aks]
}
