output "vnet_id" {
  description = "Resource ID of the virtual network."
  value       = module.vnet.resource_id
}

output "vnet_name" {
  description = "Name of the virtual network."
  value       = module.vnet.name
}

output "subnet_ids" {
  description = "Map of subnet keys to subnet resource IDs."
  value = {
    for subnet_key, subnet in module.vnet.subnets : subnet_key => subnet.resource_id
  }
}

output "private_dns_zone_id" {
  description = "Resource ID of the AKS private DNS zone."
  value       = azurerm_private_dns_zone.aks.id
}
