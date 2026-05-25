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

output "vpn_gateway_public_ip" {
  value       = module.vpn_gateway.public_ip_address
  description = "Public IP address of the VPN Gateway."
}

output "dns_resolver_inbound_ip" {
  value       = module.dns_resolver.inbound_endpoint_ip
  description = "IP address of the DNS resolver inbound endpoint (use as DNS server in VPN client)."
}
