# AKS Private Cluster Template

A template implementation of an Azure Kubernetes Service (AKS) cluster deployed within a private virtual network, using Terraform [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/) where available. Intended for demonstration and reference purposes.

## Architecture

The infrastructure is split into two layers:

### Backend (Bicep) — deployed via GitHub Actions on `ubuntu-latest`

Creates the foundational networking and CI/CD runner:

- **Virtual Network** — Shared VNet for all resources (10.0.0.0/16)
- **Runner Subnet** — Dedicated subnet for the self-hosted GitHub Actions runner
- **Private Endpoint Subnet** — For the state storage private endpoint
- **NAT Gateway** — Outbound internet for the runner
- **Storage Account** — Terraform state file (Entra ID auth, no shared keys)
- **Private Endpoint** — Private connectivity from runner to state storage
- **Private DNS Zone** — `privatelink.blob.core.windows.net` for blob resolution
- **GitHub Actions Runner VM** — Self-hosted Linux runner registered to this repo

### Main Infrastructure (Terraform) — deployed via GitHub Actions on `self-hosted` runner

Deploys into the existing VNet created by the backend:

- **AKS Cluster** — Private cluster with no public API endpoint
- **Private DNS Zone** — For AKS internal name resolution
- **Azure Bastion** — Secure remote access without exposing VMs to the internet
- **Jumpbox VMs** — Linux + Windows for administrative access
- **Azure Container Registry (ACR)** — Private image registry with VNet integration
- **Azure Key Vault** — Secrets and certificate management
- **Log Analytics Workspace** — Observability and container insights
- **NAT Gateway** — Controlled egress for AKS subnet
- **Storage Account** — Application persistent storage

## Deployment Flow

```
1. Deploy Backend (Bicep)     →  VNet, Runner, State Storage
   (runs on: ubuntu-latest)

2. Deploy Terraform Infra     →  AKS, ACR, Bastion, etc.
   (runs on: self-hosted)        Uses VNet from step 1
```

## Prerequisites

- Azure subscription with Owner role
- Azure AD app registration with OIDC federation for GitHub Actions
- GitHub personal access token (for runner registration)

## GitHub Secrets Required

| Secret | Purpose |
|--------|---------|
| `ARM_CLIENT_ID` | Azure AD app registration client ID (OIDC) |
| `ARM_SUBSCRIPTION_ID` | Azure subscription ID |
| `ARM_TENANT_ID` | Azure AD tenant ID |
| `RUNNER_TOKEN` | PAT for runner registration |
| `TFSTATE_RESOURCE_GROUP` | Backend resource group name |
| `TFSTATE_STORAGE_ACCOUNT` | Backend storage account name |
| `TFSTATE_CONTAINER` | Blob container for state (`tfstate`) |
| `TFSTATE_KEY` | State file key (`aks-private.tfstate`) |

All secrets are configured in the **`dev`** GitHub environment.

## Usage

### Deploy Backend

Trigger the **Deploy Backend Infrastructure (Bicep)** workflow manually from the Actions tab.

### Deploy Terraform Infrastructure

The **Terraform CI/CD** workflow runs automatically on push to `main`, or can be triggered manually with `plan`, `apply`, or `destroy` actions.

### Local Development

```bash
# Initialize with backend config
terraform init \
  -backend-config="resource_group_name=rg-aks-backend-westeurope" \
  -backend-config="storage_account_name=staksdemostate2026" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=aks-private.tfstate" \
  -backend-config="use_azuread_auth=true"

terraform plan -out=tfplan
terraform apply tfplan
```

## Purpose

This repo serves as a reusable starting point for deploying production-like private AKS environments for demos, workshops, and proof-of-concept work.
