# Copilot Instructions

## Project Overview

Terraform template for a private AKS cluster deployed inside a VNet using [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/) where available. Designed for demos and proof-of-concept work.

### Key Components

- Private AKS cluster (Azure CNI Overlay + Cilium dataplane + ACNS)
- Point-to-Site VPN Gateway with Entra ID authentication
- Private DNS Resolver for VPN client DNS resolution
- Private DNS zones for internal resolution
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
- No public IPs except on the VPN Gateway (required by design)
- Local developer access via P2S VPN + Private DNS Resolver (no bastion/jumpbox)

## Terraform Conventions

- State files and `.tfvars` are excluded from version control
- Provide secrets and environment-specific values via `terraform.tfvars` (never hardcode)
- Override files (`*_override.tf`) are for local use only and must not be committed
- Follow AVM naming patterns: use `name`, `resource_group_name`, `location` as top-level variables
