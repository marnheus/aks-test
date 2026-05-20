variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where the runner VM will be deployed."
}

variable "location" {
  type        = string
  description = "Azure region for the runner resources."
}

variable "subnet_id" {
  type        = string
  description = "ID of the private runner subnet where the NIC will be attached."
}

variable "vm_name" {
  type        = string
  description = "Name of the GitHub Actions runner virtual machine."
}

variable "admin_username" {
  type        = string
  description = "Admin username for SSH access to the runner VM."
  default     = "azureadmin"
}

variable "vm_size" {
  type        = string
  description = "Azure VM size for the GitHub Actions runner."
  default     = "Standard_B2s"
}

variable "github_runner_token" {
  type        = string
  description = "GitHub PAT or runner registration token used to register the self-hosted runner."
  sensitive   = true
}

variable "github_repository" {
  type        = string
  description = "GitHub repository in owner/repo format where the runner will be registered."

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repository))
    error_message = "github_repository must be in owner/repo format."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all runner resources."
}
