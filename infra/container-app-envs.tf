resource "azurerm_container_app_environment" "primary" {
  name                       = "${local.name_prefix}-cae1"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location_primary
  log_analytics_workspace_id = azurerm_log_analytics_workspace.primary.id
}

resource "azurerm_container_app_environment" "secondary" {
  name                       = "${local.name_prefix}-cae2"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location_secondary
  log_analytics_workspace_id = azurerm_log_analytics_workspace.secondary.id
}
