terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.46.0, < 5.0.0"
    }
  }
}

data "azurerm_client_config" "current" {}

locals {
  resource_group_id = var.resource_group_id
}

resource "azurerm_user_assigned_identity" "control_plane" {
  name                = "${var.cluster_name}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "control_plane_subnet_network_contributor" {
  scope                            = var.subnet_id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.control_plane.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "control_plane_private_dns_zone_contributor" {
  scope                            = var.private_dns_zone_id
  role_definition_name             = "Private DNS Zone Contributor"
  principal_id                     = azurerm_user_assigned_identity.control_plane.principal_id
  skip_service_principal_aad_check = true
}

module "aks" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "~> 0.4"

  name                  = var.cluster_name
  location              = var.location
  parent_id             = local.resource_group_id
  kubernetes_version    = var.kubernetes_version
  public_network_access = "Disabled"
  tags                  = var.tags
  enable_telemetry      = false

  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = toset([azurerm_user_assigned_identity.control_plane.id])
  }

  api_server_access_profile = {
    enable_private_cluster             = true
    enable_private_cluster_public_fqdn = false
    private_dns_zone                   = var.private_dns_zone_id
  }

  default_agent_pool = {
    name                = "systempool"
    vm_size             = "Standard_D2s_v3"
    vnet_subnet_id      = var.subnet_id
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 3
    os_disk_size_gb     = 128
    os_type             = "Linux"
    type                = "VirtualMachineScaleSets"
    upgrade_settings = {
      max_surge = "33%"
    }
  }

  agent_pools = {
    userpool = {
      name                = "userpool"
      mode                = "User"
      vm_size             = "Standard_D4s_v3"
      vnet_subnet_id      = var.subnet_id
      enable_auto_scaling = true
      min_count           = 0
      max_count           = 5
      os_disk_size_gb     = 128
      os_type             = "Linux"
      type                = "VirtualMachineScaleSets"
      upgrade_settings = {
        max_surge = "33%"
      }
    }
  }

  network_profile = {
    load_balancer_sku   = "standard"
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_dataplane   = "cilium"
    network_policy      = "cilium"
    pod_cidr            = "192.168.0.0/16"
    service_cidr        = "172.16.0.0/16"
    dns_service_ip      = "172.16.0.10"
    advanced_networking = {
      enabled = true
      observability = {
        enabled = true
      }
      security = {
        enabled = true
      }
    }
  }

  oidc_issuer_profile = {
    enabled = true
  }

  security_profile = {
    workload_identity = {
      enabled = true
    }
  }

  addon_profile_key_vault_secrets_provider = var.key_vault_secrets_provider_enabled ? {
    enabled = true
    config = {
      enable_secret_rotation = true
    }
  } : null

  addon_profile_oms_agent = {
    enabled = true
    config = {
      log_analytics_workspace_resource_id = var.log_analytics_workspace_id
    }
  }

  depends_on = [
    azurerm_role_assignment.control_plane_private_dns_zone_contributor,
    azurerm_role_assignment.control_plane_subnet_network_contributor,
  ]
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                            = var.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = module.aks.kubelet_identity.objectId
  skip_service_principal_aad_check = true
}
