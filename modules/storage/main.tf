terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.4.0"

  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  public_network_access_enabled = false

  containers = {
    persistent_volumes = {
      name = "persistent-volumes"
    }
  }

  private_endpoints_manage_dns_zone_group = true
  private_endpoints = {
    blob = {
      name                          = "pe-blob-${var.storage_account_name}"
      subnet_resource_id            = var.private_endpoint_subnet_id
      subresource_name              = "blob"
      private_dns_zone_resource_ids = toset(var.private_dns_zone_ids)
    }
  }

  tags = var.tags
}
