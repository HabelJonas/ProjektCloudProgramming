resource "azurerm_log_analytics_workspace" "primary" {
  name                = "${local.name_prefix}-law1"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location_primary
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_log_analytics_workspace" "secondary" {
  name                = "${local.name_prefix}-law2"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location_secondary
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
