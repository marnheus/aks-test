module "workspace" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "~> 0.4.0"

  name                = var.workspace_name
  resource_group_name = var.resource_group_name
  location            = var.location

  log_analytics_workspace_retention_in_days = var.retention_in_days
  tags                                      = var.tags
}
