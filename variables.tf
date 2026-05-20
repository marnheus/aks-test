variable "location" {
  type        = string
  description = "Azure region for all resources."
  default     = "canadacentral"
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

variable "github_runner_token" {
  type        = string
  description = "GitHub personal access token for runner registration."
  sensitive   = true
}

variable "github_repository" {
  type        = string
  description = "GitHub repository in format owner/repo for runner registration."
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for AKS cluster."
  default     = "1.30"
}
