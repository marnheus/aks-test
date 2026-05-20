output "registry_id" {
  description = "Resource ID of the Azure Container Registry."
  value       = module.registry.resource_id
}

output "login_server" {
  description = "Login server URL of the Azure Container Registry."
  value       = module.registry.resource.login_server
}

output "registry_name" {
  description = "Name of the Azure Container Registry."
  value       = module.registry.name
}
