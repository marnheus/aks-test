locals {
  resource_suffix = random_string.suffix.result
  name_prefix     = "aks-demo"

  # Subnet address ranges within 10.0.0.0/16
  # Runner (10.0.250.0/24) and PE (10.0.251.0/24) subnets are managed by the Bicep backend
  subnets = {
    aks              = "10.0.0.0/22"   # /22 = 1024 IPs for AKS nodes + pods
    private_endpoint = "10.0.5.0/24"   # /24 = 256 IPs for private endpoints
  }
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Auto-generated VM admin credentials

