# Terraform backend bootstrap

Use this standalone Terraform configuration to create the Azure resources required for remote state storage.

## Usage

1. Open a terminal in `C:\Repos\aks-test\backend`.
2. Initialize Terraform:
   ```powershell
   terraform init
   ```
3. Apply the configuration with a globally unique storage account name:
   ```powershell
   terraform apply -var="storage_account_name=<globally-unique-name>"
   ```
4. Note the output values for the resource group, storage account, and container.

## Update the main Terraform backend block

After the storage resources exist, update your main `terraform` backend configuration (for example in `terraform.tf`) to point at them:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "<globally-unique-name>"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
```

Then re-run:

```powershell
terraform init -reconfigure
```
