output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "The name of the resource group."
}

output "aks_cluster_name" {
  value       = module.aks.cluster_name
  description = "The name of the AKS cluster."
}

output "acr_login_server" {
  value       = module.acr.login_server
  description = "The login server URL of the container registry."
}

output "key_vault_uri" {
  value       = module.keyvault.vault_uri
  description = "The URI of the Key Vault."
}
