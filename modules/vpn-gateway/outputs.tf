output "gateway_id" {
  value       = azurerm_virtual_network_gateway.this.id
  description = "The ID of the VPN Gateway."
}

output "public_ip_address" {
  value       = azurerm_public_ip.vpn_gateway.ip_address
  description = "The public IP of the VPN Gateway."
}

output "gateway_name" {
  value       = azurerm_virtual_network_gateway.this.name
  description = "The name of the VPN Gateway."
}
