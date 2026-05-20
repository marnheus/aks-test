output "storage_account_name" {
  description = "Name of the storage account used for Terraform state."
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "Name of the blob container used for Terraform state."
  value       = azurerm_storage_container.tfstate.name
}

output "resource_group_name" {
  description = "Name of the resource group containing the Terraform state resources."
  value       = azurerm_resource_group.tfstate.name
}
