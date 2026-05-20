output "storage_account_id" {
  description = "Storage Account resource ID."
  value       = module.storage_account.resource_id
}

output "storage_account_name" {
  description = "Storage Account name."
  value       = module.storage_account.name
}
