variable "resource_group_name" {
  type        = string
  description = "Name of the resource group that contains the storage account."
}

variable "location" {
  type        = string
  description = "Azure region for the storage account resources."
}

variable "storage_account_name" {
  type        = string
  description = "Globally unique name for the Azure Storage Account."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the storage account and related resources."
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet resource ID used for the blob private endpoint."
}

variable "private_dns_zone_ids" {
  type        = list(string)
  description = "Private DNS zone resource IDs associated with the blob private endpoint."
}
