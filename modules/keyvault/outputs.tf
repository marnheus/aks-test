output "vault_id" {
  description = "Resource ID of the Azure Key Vault."
  value       = module.key_vault.resource_id
}

output "vault_uri" {
  description = "URI of the Azure Key Vault."
  value       = module.key_vault.uri
}

output "vault_name" {
  description = "Name of the Azure Key Vault."
  value       = var.vault_name
}
