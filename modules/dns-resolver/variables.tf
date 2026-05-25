variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "resolver_name" {
  type        = string
  description = "Name of the Private DNS Resolver."
}

variable "virtual_network_id" {
  type        = string
  description = "ID of the VNet where the resolver is deployed."
}

variable "inbound_subnet_id" {
  type        = string
  description = "ID of the subnet for the inbound endpoint (must have Microsoft.Network/dnsResolvers delegation)."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources."
  default     = {}
}
