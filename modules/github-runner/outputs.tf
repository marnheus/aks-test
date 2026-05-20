output "vm_id" {
  description = "Resource ID of the GitHub Actions runner VM."
  value       = azurerm_linux_virtual_machine.runner.id
}

output "vm_name" {
  description = "Name of the GitHub Actions runner VM."
  value       = azurerm_linux_virtual_machine.runner.name
}

output "vm_identity_principal_id" {
  description = "Principal ID of the runner VM system-assigned managed identity."
  value       = azurerm_linux_virtual_machine.runner.identity[0].principal_id
}
