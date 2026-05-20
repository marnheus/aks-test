output "bastion_id" {
  description = "Resource ID of the Azure Bastion host."
  value       = module.bastion.resource_id
}

output "bastion_name" {
  description = "Name of the Azure Bastion host."
  value       = module.bastion.name
}
