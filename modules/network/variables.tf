variable "resource_group_name" {
  description = "Name of the resource group where the network resources are deployed."
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
  description = "Name of the virtual network."
  type        = string

  validation {
    condition     = length(trimspace(var.vnet_name)) > 0
    error_message = "vnet_name must not be empty."
  }
}

variable "address_space" {
  description = "Address space assigned to the virtual network."
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "address_space must contain at least one CIDR block."
  }

  validation {
    condition     = alltrue([for cidr in var.address_space : can(cidrhost(cidr, 0))])
    error_message = "Each address_space entry must be a valid CIDR block."
  }
}

variable "subnets" {
  description = "Map of subnet definitions keyed by logical subnet name. Use name_override to change the Azure subnet name; bastion must resolve to AzureBastionSubnet."
  type = map(object({
    address_prefix = string
    name_override  = optional(string)
  }))

  validation {
    condition     = length(var.subnets) > 0
    error_message = "subnets must contain at least one subnet definition."
  }

  validation {
    condition     = alltrue([for subnet in values(var.subnets) : can(cidrhost(subnet.address_prefix, 0))])
    error_message = "Each subnet address_prefix must be a valid CIDR block."
  }

  validation {
    condition = length(distinct([
      for subnet_key, subnet in var.subnets : coalesce(try(subnet.name_override, null), subnet_key)
    ])) == length(var.subnets)
    error_message = "Each subnet must resolve to a unique Azure subnet name."
  }

  validation {
    condition = !contains(keys(var.subnets), "AzureBastionSubnet") || coalesce(
      try(var.subnets["AzureBastionSubnet"].name_override, null),
      "AzureBastionSubnet"
    ) == "AzureBastionSubnet"
    error_message = "If the bastion subnet key is AzureBastionSubnet, its effective Azure subnet name must remain AzureBastionSubnet."
  }
}

variable "tags" {
  description = "Tags applied to all supported resources."
  type        = map(string)
  default     = {}
}
