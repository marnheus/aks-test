output "cluster_id" {
  description = "Resource ID of the AKS cluster."
  value       = module.aks.resource_id
}

output "cluster_name" {
  description = "Name of the AKS cluster."
  value       = module.aks.name
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet managed identity used for ACR pull."
  value       = try(module.aks.kubelet_identity.objectId, null)
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL exposed by the AKS cluster for workload identity federation."
  value       = module.aks.oidc_issuer_profile_issuer_url
}
