module "bastion" {
  source  = "Azure/avm-res-network-bastionhost/azurerm"
  version = "~> 0.4"

  name              = var.bastion_name
  location          = var.location
  parent_id         = data.azurerm_resource_group.this.id
  sku               = "Standard"
  tunneling_enabled = true

  ip_configuration = {
    name                   = "${var.bastion_name}-ipconfig"
    subnet_id              = var.subnet_id
    create_public_ip       = true
    public_ip_address_name = "${var.bastion_name}-pip"
    public_ip_tags         = var.tags
  }

  tags = var.tags
}

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}
