variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where the Log Analytics workspace will be deployed."
  nullable    = false
}

variable "location" {
  type        = string
  description = "Azure region where the Log Analytics workspace will be deployed."
  nullable    = false
}

variable "workspace_name" {
  type        = string
  description = "Name of the Log Analytics workspace."
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]{2,61}[A-Za-z0-9]$", var.workspace_name))
    error_message = "workspace_name must be 4-63 characters, use only letters, numbers, and hyphens, start with an alphanumeric character, and end with an alphanumeric character."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Log Analytics workspace."
  nullable    = false
}

variable "retention_in_days" {
  type        = number
  description = "Number of days to retain workspace data. Use 30 days for the demo environment by default."
  default     = 30
  nullable    = false

  validation {
    condition     = var.retention_in_days == 7 || (var.retention_in_days >= 30 && var.retention_in_days <= 730)
    error_message = "retention_in_days must be 7 or between 30 and 730 days."
  }
}
