output "nat_gateway_id" {
  description = "Resource ID of the NAT Gateway."
  value       = azurerm_nat_gateway.this.id
}
