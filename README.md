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

- **AKS Cluster** — Private cluster with no public API endpoint, Azure CNI Overlay, Cilium dataplane
- **ACNS (Advanced Container Networking Services)** — Observability and security features powered by Cilium
- **Private DNS Zone** — For AKS internal name resolution (`privatelink.westeurope.azmk8s.io`)
- **VPN Gateway** — Point-to-Site VPN with Entra ID authentication for local developer access
- **Private DNS Resolver** — Inbound endpoint enabling VPN clients to resolve private DNS zones
- **Azure Container Registry (ACR)** — Private image registry with VNet integration
- **Azure Key Vault** — Secrets and certificate management
- **Log Analytics Workspace** — Observability and container insights
- **NAT Gateway** — Controlled egress for AKS subnet
- **Storage Account** — Application persistent storage

## Deployment Flow

```
1. Deploy Backend (Bicep)     →  VNet, Runner, State Storage
   (runs on: ubuntu-latest)

2. Deploy Terraform Infra     →  AKS, ACR, VPN, DNS Resolver, etc.
   (runs on: self-hosted)        Uses VNet from step 1
```

## Prerequisites

- Azure subscription with Owner role
- Azure AD app registration with OIDC federation for GitHub Actions
- GitHub personal access token (for runner registration)

## GitHub Secrets Required (in `dev` environment)

| Secret | Purpose |
|--------|---------|
| `ARM_CLIENT_ID` | Azure AD app registration client ID (OIDC) |
| `ARM_SUBSCRIPTION_ID` | Azure subscription ID |
| `ARM_TENANT_ID` | Azure AD tenant ID |
| `RUNNER_TOKEN` | PAT for runner registration |

## GitHub Environment Variables (in `dev` environment)

| Variable | Purpose |
|----------|---------|
| `TFSTATE_RESOURCE_GROUP` | Backend resource group name |
| `TFSTATE_STORAGE_ACCOUNT` | Backend storage account name |
| `TFSTATE_CONTAINER` | Blob container for state (`tfstate`) |
| `TFSTATE_KEY` | State file key (`aks-private.tfstate`) |

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

## Networking

| Subnet | CIDR | Purpose |
|--------|------|---------|
| AKS | 10.0.0.0/22 | AKS node pool |
| Runner | 10.0.5.0/24 | GitHub Actions self-hosted runner |
| Private Endpoints | 10.0.4.64/26 | Private endpoints (ACR, Key Vault, Storage) |
| GatewaySubnet | 10.0.4.0/27 | VPN Gateway (required name by Azure) |
| DNS Resolver | 10.0.6.0/28 | Private DNS Resolver inbound endpoint |

- **Pod CIDR (Overlay)**: 192.168.0.0/16
- **Service CIDR**: 172.16.0.0/16
- **VPN Client Address Pool**: 172.16.201.0/24

## Local Access via VPN

The infrastructure includes a Point-to-Site VPN Gateway with Entra ID authentication, allowing developers to access private resources from their local machines.

### Setup

1. Download the VPN profile from the `vpn-profiles` container in the state storage account (`staksdemostate2026`)
2. Import `azurevpnconfig.xml` into the [Azure VPN Client](https://aka.ms/azvpnclientdownload)
3. Connect using your Entra ID credentials

### DNS Resolution

The Private DNS Resolver (inbound IP: configured in the VPN profile) enables VPN clients to resolve private DNS zones:
- `privatelink.westeurope.azmk8s.io` (AKS API server)
- `privatelink.azurecr.io` (Container Registry)
- `privatelink.vaultcore.azure.net` (Key Vault)
- `privatelink.blob.core.windows.net` (Storage)

### Connecting to the Cluster

```bash
az aks get-credentials --resource-group rg-aks-demo-westeurope --name <cluster-name>
kubectl get nodes
```

## AKS Cluster Configuration

- **Network Plugin**: Azure CNI with Overlay mode
- **Network Dataplane**: Cilium
- **Network Policy**: Cilium
- **ACNS**: Enabled (observability + security)
- **SKU**: Standard with system + user node pools
- **Authentication**: Workload Identity + OIDC issuer enabled
- **Monitoring**: Container Insights via Log Analytics
