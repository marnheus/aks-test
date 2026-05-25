variable "location" {
  type        = string
  description = "Azure region for all resources."
  default     = "westeurope"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
  default = {
    environment = "demo"
    managed_by  = "terraform"
  }
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the virtual network."
  default     = ["10.0.0.0/16"]
}

variable "backend_resource_group" {
  type        = string
  description = "Name of the resource group containing the backend VNet (deployed by Bicep)."
}

variable "backend_vnet_name" {
  type        = string
  description = "Name of the VNet created by the Bicep backend."
}

variable "backend_storage_account_name" {
  type        = string
  description = "Name of the backend storage account (Terraform state)."
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for AKS cluster."
  default     = "1.33"
}
