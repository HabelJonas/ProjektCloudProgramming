resource "azurerm_container_registry" "acr" {
  count               = var.use_existing_acr ? 0 : 1
  name                = local.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location_primary
  sku                 = "Basic"
  admin_enabled       = false
}

data "azurerm_container_registry" "acr" {
  count               = var.use_existing_acr ? 1 : 0
  name                = local.acr_name
  resource_group_name = local.acr_resource_group_name
}
