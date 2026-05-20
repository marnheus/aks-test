terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}

locals {
  linux_vm_name         = "${var.name_prefix}-linux-jumpbox"
  windows_vm_name       = "${var.name_prefix}-windows-jumpbox"
  linux_computer_name   = substr("${replace(var.name_prefix, "-", "")}linux", 0, 64)
  windows_computer_name = substr("${replace(var.name_prefix, "-", "")}win", 0, 15)
}

resource "tls_private_key" "linux_admin" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_network_interface" "linux" {
  name                = "${local.linux_vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.subnet_id
  }
}

resource "azurerm_network_interface" "windows" {
  name                = "${local.windows_vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.subnet_id
  }
}

resource "azurerm_linux_virtual_machine" "linux" {
  name                            = local.linux_vm_name
  computer_name                   = local.linux_computer_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.linux.id]
  tags                            = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.linux_admin.public_key_openssh
  }

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_windows_virtual_machine" "windows" {
  name                  = local.windows_vm_name
  computer_name         = local.windows_computer_name
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.windows.id]
  tags                  = var.tags

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }
}
