output "workspace_id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = module.workspace.resource_id
}

output "workspace_name" {
  description = "Name of the Log Analytics workspace."
  value       = nonsensitive(module.workspace.resource.name)
}
