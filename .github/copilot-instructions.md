# Copilot Instructions

## Project Overview

Terraform template for a private AKS cluster deployed inside a VNet using [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/) where available. Designed for demos and proof-of-concept work.

### Key Components

- Private AKS cluster (no public API endpoint)
- Private DNS zone for internal resolution
- Azure Bastion for secure access
- Jumpbox VM for cluster administration
- Private GitHub Actions self-hosted runner
- Azure Container Registry (ACR) with VNet integration
- Azure Key Vault for secrets/certificate management
- Log Analytics Workspace + Azure Monitor (container insights)
- NAT Gateway for controlled egress
- Storage Account for persistent volumes

## Commands

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform destroy
```

## Architecture Conventions

- All resources deploy inside a single private VNet with dedicated subnets per workload
- Prefer AVM modules from the Terraform registry (`Azure/avm-res-*`) over hand-written resource blocks
- Use private endpoints for any service that supports them (ACR, AKS API, etc.)
- No public IPs except on the Azure Bastion subnet (required by design)

## Terraform Conventions

- State files and `.tfvars` are excluded from version control
- Provide secrets and environment-specific values via `terraform.tfvars` (never hardcode)
- Override files (`*_override.tf`) are for local use only and must not be committed
- Follow AVM naming patterns: use `name`, `resource_group_name`, `location` as top-level variables
