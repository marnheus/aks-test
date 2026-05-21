locals {
  resource_suffix = random_string.suffix.result
  name_prefix     = "aks-demo"

  # Subnet address ranges within 10.0.0.0/16
  # Runner (10.0.250.0/24) and PE (10.0.251.0/24) subnets are managed by the Bicep backend
  subnets = {
    aks              = "10.0.0.0/22"   # /22 = 1024 IPs for AKS nodes + pods
    bastion          = "10.0.4.0/26"   # /26 = 64 IPs (Azure Bastion requirement)
    jumpbox          = "10.0.4.64/26"  # /26 = 64 IPs
    private_endpoint = "10.0.5.0/24"   # /24 = 256 IPs for private endpoints
  }
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Auto-generated VM admin credentials
resource "random_pet" "jumpbox_admin_username" {
  length    = 2
  separator = ""
}

resource "random_password" "jumpbox_windows_password" {
  length           = 24
  special          = true
  override_special = "!@#$%^&*"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

# Grant the deployer Key Vault Secrets Officer role to write secrets
resource "azurerm_role_assignment" "deployer_kv_admin" {
  scope                = module.keyvault.vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Wait for RBAC propagation before writing secrets
resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.deployer_kv_admin]
  create_duration = "30s"
}

# Store VM credentials in Key Vault
resource "azurerm_key_vault_secret" "jumpbox_admin_username" {
  name         = "jumpbox-admin-username"
  value        = random_pet.jumpbox_admin_username.id
  key_vault_id = module.keyvault.vault_id

  depends_on = [time_sleep.wait_for_rbac]
}

resource "azurerm_key_vault_secret" "jumpbox_admin_password" {
  name         = "jumpbox-admin-password"
  value        = random_password.jumpbox_windows_password.result
  key_vault_id = module.keyvault.vault_id

  depends_on = [time_sleep.wait_for_rbac]
}


