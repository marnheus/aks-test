locals {
  resource_suffix = random_string.suffix.result
  name_prefix     = "aks-demo"

  # Subnet address ranges within 10.0.0.0/16
  subnets = {
    aks              = "10.0.0.0/22"   # /22 = 1024 IPs for AKS nodes + pods
    bastion          = "10.0.4.0/26"   # /26 = 64 IPs (Azure Bastion requirement)
    jumpbox          = "10.0.4.64/26"  # /26 = 64 IPs
    runner           = "10.0.4.128/26" # /26 = 64 IPs
    private_endpoint = "10.0.5.0/24"   # /24 = 256 IPs for private endpoints
  }
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}
