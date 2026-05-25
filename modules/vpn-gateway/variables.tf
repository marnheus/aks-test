variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "gateway_name" {
  type        = string
  description = "Name of the VPN Gateway."
}

variable "gateway_subnet_id" {
  type        = string
  description = "ID of the GatewaySubnet."
}

variable "vpn_client_address_pool" {
  type        = string
  description = "CIDR for VPN client address pool."
  default     = "172.16.0.0/24"
}

variable "tenant_id" {
  type        = string
  description = "Entra ID (Azure AD) tenant ID for VPN authentication."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources."
  default     = {}
}
