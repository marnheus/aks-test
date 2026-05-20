data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_name           = "${local.name_prefix}-vnet-${local.resource_suffix}"
  address_space       = var.vnet_address_space
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

module "nat_gateway" {
  source = "./modules/nat-gateway"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  nat_gateway_name    = "${local.name_prefix}-nat-${local.resource_suffix}"
  subnet_ids = {
    aks    = module.network.subnet_ids["aks"]
    runner = module.network.subnet_ids["runner"]
  }
  tags = var.tags
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
    blob     = "privatelink.blob.core.windows.net"
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
  virtual_network_id    = module.network.vnet_id
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
  private_dns_zone_ids       = [azurerm_private_dns_zone.private_link["blob"].id]
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
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = var.tags
}

module "github_runner" {
  source = "./modules/github-runner"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = module.network.subnet_ids["runner"]
  vm_name             = "${local.name_prefix}-runner-${local.resource_suffix}"
  admin_username      = var.admin_username
  github_runner_token = var.github_runner_token
  github_repository   = var.github_repository
  tags                = var.tags

  depends_on = [module.nat_gateway]
}

module "aks" {
  source = "./modules/aks"

  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  cluster_name               = "${local.name_prefix}-aks-${local.resource_suffix}"
  kubernetes_version         = var.kubernetes_version
  subnet_id                  = module.network.subnet_ids["aks"]
  log_analytics_workspace_id = module.monitoring.workspace_id
  private_dns_zone_id        = module.network.private_dns_zone_id
  acr_id                     = module.acr.registry_id
  tags                       = var.tags

  depends_on = [module.nat_gateway]
}
