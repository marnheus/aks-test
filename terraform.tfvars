location            = "westeurope"
resource_group_name = "rg-aks-demo-westeurope"

# Backend infrastructure (deployed by Bicep)
backend_resource_group       = "rg-aks-backend-westeurope"
backend_vnet_name            = "vnet-aksbackend"
backend_storage_account_name = "staksdemostate2026"

# AKS
kubernetes_version = "1.33"

# Tags
tags = {
  environment = "demo"
  managed_by  = "terraform"
  project     = "aks-demo"
}
