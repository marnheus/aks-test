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

// Backend storage account (Terraform state + VPN profiles)
data "azurerm_storage_account" "backend" {
  name                = var.backend_storage_account_name
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
      subnet_name == "dns_resolver" ? {
        delegations = [{
          name         = "dns-resolver"
          service_name = "Microsoft.Network/dnsResolvers"
        }]
      } : {}
    )
  }
  tags = var.tags
}

# GatewaySubnet (must be named exactly "GatewaySubnet", cannot have NSG)
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.backend_resource_group
  virtual_network_name = var.backend_vnet_name
  address_prefixes     = [local.gateway_subnet_prefix]
}

// NAT Gateway is created by the Bicep backend; associate it with Terraform-managed subnets
data "azurerm_nat_gateway" "backend" {
  name                = "natgw-aksbackend-runner"
  resource_group_name = var.backend_resource_group
}

resource "azurerm_subnet_nat_gateway_association" "aks" {
  subnet_id      = module.network.subnet_ids["aks"]
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

// GitHub runner is deployed by the Bicep backend (see backend/main.bicep)

module "vpn_gateway" {
  source = "./modules/vpn-gateway"

  resource_group_name     = var.backend_resource_group
  location                = azurerm_resource_group.main.location
  gateway_name            = "${local.name_prefix}-vpngw-${local.resource_suffix}"
  gateway_subnet_id       = azurerm_subnet.gateway.id
  vpn_client_address_pool = "172.16.0.0/24"
  tenant_id               = data.azurerm_client_config.current.tenant_id
  tags                    = var.tags
}

module "dns_resolver" {
  source = "./modules/dns-resolver"

  resource_group_name = var.backend_resource_group
  location            = azurerm_resource_group.main.location
  resolver_name       = "${local.name_prefix}-dnsresolver-${local.resource_suffix}"
  virtual_network_id  = data.azurerm_virtual_network.backend.id
  inbound_subnet_id   = module.network.subnet_ids["dns_resolver"]
  tags                = var.tags
}

# Generate VPN client profile with DNS resolver IP
locals {
  vpn_profile_xml = <<-XML
<?xml version="1.0"?>
<AzVpnProfile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <Name>aks-demo-vpn</Name>
  <ServerAddress>${module.vpn_gateway.public_ip_address}</ServerAddress>
  <ServerRootCertificate>
    <Name>DigiCert Global Root G2</Name>
    <Fingerprint>cb3ccbb76031e5e0138f8dd631a97af550b14c44</Fingerprint>
  </ServerRootCertificate>
  <ClientAuthentication>
    <Type>AAD</Type>
    <AADTenant>https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/</AADTenant>
    <AADAudience>c632b3df-fb67-4d84-bdcf-b95ad541b5c8</AADAudience>
    <AADIssuer>https://sts.windows.net/${data.azurerm_client_config.current.tenant_id}/</AADIssuer>
  </ClientAuthentication>
  <DNS>
    <Server>${module.dns_resolver.inbound_endpoint_ip}</Server>
  </DNS>
</AzVpnProfile>
  XML
}

# Upload VPN profile to storage account
resource "azurerm_storage_container" "vpn_profiles" {
  name                 = "vpn-profiles"
  storage_account_id   = data.azurerm_storage_account.backend.id
}

resource "azurerm_storage_blob" "vpn_profile" {
  name                   = "azurevpnconfig.xml"
  storage_account_name   = data.azurerm_storage_account.backend.name
  storage_container_name = azurerm_storage_container.vpn_profiles.name
  type                   = "Block"
  source_content         = local.vpn_profile_xml
  content_type           = "application/xml"
}

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
