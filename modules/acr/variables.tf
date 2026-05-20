variable "resource_group_name" {
  type        = string
  description = "Name of the resource group that hosts the container registry."
}

variable "location" {
  type        = string
  description = "Azure region where the container registry and private endpoint are deployed."
}

variable "registry_name" {
  type        = string
  description = "Name of the Azure Container Registry."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the container registry and private endpoint."
  default     = {}
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Resource ID of the subnet where the private endpoint will be created."
}

variable "private_dns_zone_ids" {
  type        = list(string)
  description = "Private DNS zone resource IDs associated with the container registry private endpoint."
  default     = []
}
