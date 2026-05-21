variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where the Bastion host is deployed."
}

variable "resource_group_id" {
  type        = string
  description = "Resource ID of the resource group where the Bastion host is deployed."
}

variable "location" {
  type        = string
  description = "Azure region for the Bastion host."
}

variable "bastion_name" {
  type        = string
  description = "Name of the Azure Bastion host."
}

variable "subnet_id" {
  type        = string
  description = "Resource ID of the AzureBastionSubnet."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Bastion host and managed public IP."
  default     = {}
}
