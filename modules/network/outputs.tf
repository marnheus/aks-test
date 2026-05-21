output "vnet_id" {
  description = "Resource ID of the virtual network."
  value       = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${var.vnet_name}"
}

output "vnet_name" {
  description = "Name of the virtual network."
  value       = var.vnet_name
}

output "subnet_ids" {
  description = "Map of subnet keys to subnet resource IDs."
  value = {
    for subnet_key, subnet in azurerm_subnet.subnet : subnet_key => subnet.id
  }
}

output "private_dns_zone_id" {
  description = "Resource ID of the AKS private DNS zone."
  value       = azurerm_private_dns_zone.aks.id
}
