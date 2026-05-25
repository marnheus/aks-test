module "bastion" {
  source  = "Azure/avm-res-network-bastionhost/azurerm"
  version = "~> 0.4"

  name              = var.bastion_name
  location          = var.location
  parent_id         = var.resource_group_id
  sku               = "Standard"
  tunneling_enabled = true

  ip_configuration = {
    name                   = "${var.bastion_name}-ipconfig"
    subnet_id              = var.subnet_id
    create_public_ip       = true
    public_ip_address_name = "${var.bastion_name}-pip"
  }

  tags = var.tags
}
