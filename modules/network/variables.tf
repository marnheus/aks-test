variable "resource_group_name" {
  description = "Name of the resource group where the VNet exists (backend RG)."
  type        = string

  validation {
    condition     = length(trimspace(var.resource_group_name)) > 0
    error_message = "resource_group_name must not be empty."
  }
}

variable "location" {
  description = "Azure region where the network resources are deployed."
  type        = string

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must not be empty."
  }
}

variable "vnet_name" {
  description = "Name of the existing virtual network (created by Bicep backend)."
  type        = string

  validation {
    condition     = length(trimspace(var.vnet_name)) > 0
    error_message = "vnet_name must not be empty."
  }
}

variable "address_space" {
  description = "Address space assigned to the virtual network (for reference only, VNet is managed by Bicep)."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "existing_vnet" {
  description = "Whether to use an existing VNet (true) or create a new one (false). Must be true - VNet is created by Bicep backend."
  type        = bool
  default     = true
}

variable "subnets" {
  description = "Map of subnet definitions keyed by logical subnet name. Use name_override to change the Azure subnet name."
  type = map(object({
    address_prefix = string
    name_override  = optional(string)
    delegations = optional(list(object({
      name         = string
      service_name = string
    })), [])
  }))

  validation {
    condition     = length(var.subnets) > 0
    error_message = "subnets must contain at least one subnet definition."
  }

  validation {
    condition     = alltrue([for subnet in values(var.subnets) : can(cidrhost(subnet.address_prefix, 0))])
    error_message = "Each subnet address_prefix must be a valid CIDR block."
  }
}

variable "tags" {
  description = "Tags applied to all supported resources."
  type        = map(string)
  default     = {}
}
