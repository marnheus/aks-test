variable "resource_group_name" {
  description = "Name of the resource group where the Key Vault is deployed."
  type        = string
}

variable "location" {
  description = "Azure region for the Key Vault deployment."
  type        = string
}

variable "vault_name" {
  description = "Name of the Azure Key Vault."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the Key Vault and private endpoint resources."
  type        = map(string)
}

variable "private_endpoint_subnet_id" {
  description = "Resource ID of the subnet used for the Key Vault private endpoint."
  type        = string
}

variable "private_dns_zone_ids" {
  description = "Resource IDs of the private DNS zones linked to the Key Vault private endpoint."
  type        = list(string)
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID for the Key Vault."
  type        = string
}
