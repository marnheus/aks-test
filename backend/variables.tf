variable "location" {
  description = "Azure region for the Terraform state storage resources."
  type        = string
  default     = "canadacentral"
}

variable "resource_group_name" {
  description = "Name of the resource group that will contain the Terraform state storage resources."
  type        = string
  default     = "rg-terraform-state"
}

variable "storage_account_name" {
  description = "Globally unique name for the storage account that will hold Terraform state."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 characters of lowercase letters and numbers."
  }
}

variable "tags" {
  description = "Tags to apply to the Terraform state resources."
  type        = map(string)
  default     = {}
}
