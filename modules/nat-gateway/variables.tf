variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where the NAT Gateway resources will be deployed."
}

variable "location" {
  type        = string
  description = "Azure region for the NAT Gateway resources."
}

variable "nat_gateway_name" {
  type        = string
  description = "Name of the NAT Gateway."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the NAT Gateway and Public IP resources."
}

variable "subnet_ids" {
  type        = map(string)
  description = "Map of subnet names to subnet resource IDs to associate with the NAT Gateway."
}
