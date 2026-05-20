variable "resource_group_name" {
  description = "Name of the resource group where the jumpbox resources are deployed."
  type        = string

  validation {
    condition     = length(trimspace(var.resource_group_name)) > 0
    error_message = "resource_group_name must not be empty."
  }
}

variable "location" {
  description = "Azure region where the jumpbox resources are deployed."
  type        = string

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must not be empty."
  }
}

variable "subnet_id" {
  description = "Resource ID of the subnet where the jumpbox network interfaces are attached."
  type        = string

  validation {
    condition     = length(trimspace(var.subnet_id)) > 0
    error_message = "subnet_id must not be empty."
  }
}

variable "name_prefix" {
  description = "Prefix used when naming jumpbox resources."
  type        = string

  validation {
    condition     = length(trimspace(var.name_prefix)) > 0
    error_message = "name_prefix must not be empty."
  }
}

variable "admin_username" {
  description = "Administrator username for both jumpbox virtual machines."
  type        = string

  validation {
    condition     = length(trimspace(var.admin_username)) > 0
    error_message = "admin_username must not be empty."
  }
}

variable "admin_password" {
  description = "Administrator password for the Windows jumpbox virtual machine."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.admin_password) > 0
    error_message = "admin_password must not be empty."
  }
}

variable "tags" {
  description = "Tags applied to all supported jumpbox resources."
  type        = map(string)
  default     = {}
}

variable "vm_size" {
  description = "Azure VM size used for both jumpbox virtual machines."
  type        = string
  default     = "Standard_B2s"

  validation {
    condition     = length(trimspace(var.vm_size)) > 0
    error_message = "vm_size must not be empty."
  }
}
