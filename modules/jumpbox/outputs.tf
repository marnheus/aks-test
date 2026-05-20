output "linux_vm_id" {
  description = "Resource ID of the Linux jumpbox virtual machine."
  value       = azurerm_linux_virtual_machine.linux.id
}

output "windows_vm_id" {
  description = "Resource ID of the Windows jumpbox virtual machine."
  value       = azurerm_windows_virtual_machine.windows.id
}

output "linux_vm_name" {
  description = "Name of the Linux jumpbox virtual machine."
  value       = azurerm_linux_virtual_machine.linux.name
}

output "windows_vm_name" {
  description = "Name of the Windows jumpbox virtual machine."
  value       = azurerm_windows_virtual_machine.windows.name
}

output "linux_vm_identity_principal_id" {
  description = "Principal ID of the Linux jumpbox system-assigned managed identity."
  value       = azurerm_linux_virtual_machine.linux.identity[0].principal_id
}

output "windows_vm_identity_principal_id" {
  description = "Principal ID of the Windows jumpbox system-assigned managed identity."
  value       = azurerm_windows_virtual_machine.windows.identity[0].principal_id
}
