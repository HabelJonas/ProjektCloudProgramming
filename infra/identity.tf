resource "azurerm_user_assigned_identity" "app_identity" {
  name                = "${local.name_prefix}-uai"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location_primary
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = local.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.app_identity.principal_id
}
