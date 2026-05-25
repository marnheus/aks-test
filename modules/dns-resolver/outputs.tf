output "resolver_id" {
  value       = azurerm_private_dns_resolver.this.id
  description = "The ID of the Private DNS Resolver."
}

output "inbound_endpoint_ip" {
  value       = azurerm_private_dns_resolver_inbound_endpoint.this.ip_configurations[0].private_ip_address
  description = "The private IP of the inbound endpoint (use as DNS server for VPN clients)."
}
