# AKS Private Cluster Template

A template implementation of an Azure Kubernetes Service (AKS) cluster deployed within a private virtual network, using Terraform [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/) where available. Intended for demonstration and reference purposes.

## Architecture

This template deploys the following resources inside a private VNet:

- **AKS Cluster** — Private cluster with no public API endpoint
- **Private DNS Zone** — For internal name resolution within the VNet
- **Azure Bastion** — Secure remote access without exposing VMs to the internet
- **Jumpbox VM** — For administrative access to the private cluster
- **Private GitHub Actions Runner** — Self-hosted runner inside the VNet for CI/CD pipelines
- **Azure Container Registry (ACR)** — Private image registry with VNet integration

## Prerequisites

- Azure subscription
- Terraform >= 1.x
- Azure CLI (authenticated)
- GitHub personal access token (for runner registration)

## Usage

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Provide required variables via a `terraform.tfvars` file (not committed to source control).

## Purpose

This repo serves as a reusable starting point for deploying production-like private AKS environments for demos, workshops, and proof-of-concept work.
