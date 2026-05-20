variable "resource_group_name" {
  description = "Name of the resource group where the AKS cluster resources are deployed."
  type        = string

  validation {
    condition     = length(trimspace(var.resource_group_name)) > 0
    error_message = "resource_group_name must not be empty."
  }
}

variable "location" {
  description = "Azure region where the AKS cluster is deployed."
  type        = string

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must not be empty."
  }
}

variable "cluster_name" {
  description = "Name of the AKS cluster."
  type        = string

  validation {
    condition     = length(trimspace(var.cluster_name)) > 0
    error_message = "cluster_name must not be empty."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS control plane and node pools."
  type        = string

  validation {
    condition     = length(trimspace(var.kubernetes_version)) > 0
    error_message = "kubernetes_version must not be empty."
  }
}

variable "subnet_id" {
  description = "Resource ID of the AKS subnet used by the cluster node pools."
  type        = string

  validation {
    condition     = length(trimspace(var.subnet_id)) > 0
    error_message = "subnet_id must not be empty."
  }
}

variable "tags" {
  description = "Tags applied to supported AKS resources."
  type        = map(string)
  default     = {}
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace used for Azure Monitor Container Insights."
  type        = string

  validation {
    condition     = length(trimspace(var.log_analytics_workspace_id)) > 0
    error_message = "log_analytics_workspace_id must not be empty."
  }
}

variable "private_dns_zone_id" {
  description = "Resource ID of the AKS private DNS zone already linked to the virtual network."
  type        = string

  validation {
    condition     = length(trimspace(var.private_dns_zone_id)) > 0
    error_message = "private_dns_zone_id must not be empty."
  }
}

variable "acr_id" {
  description = "Resource ID of the Azure Container Registry that the kubelet identity should be granted AcrPull on."
  type        = string

  validation {
    condition     = length(trimspace(var.acr_id)) > 0
    error_message = "acr_id must not be empty."
  }
}

variable "key_vault_secrets_provider_enabled" {
  description = "Whether to enable the AKS Key Vault Secrets Provider add-on."
  type        = bool
  default     = true
}

