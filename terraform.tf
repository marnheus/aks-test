terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }

  # Partial backend config - populated via -backend-config in CI/CD
  # Required backend-config keys: resource_group_name, storage_account_name, container_name, key
  backend "azurerm" {
    use_azuread_auth = true
  }
}
