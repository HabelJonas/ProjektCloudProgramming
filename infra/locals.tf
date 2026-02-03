resource "random_string" "acr_suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "random_string" "fd_suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

# Derived names and the final image reference used by Container Apps.
locals {
  sanitized_name          = lower(join("", regexall("[a-z0-9]", var.project_name)))
  name_prefix             = length(local.sanitized_name) > 0 ? substr(local.sanitized_name, 0, 18) : "app"
  acr_name                = var.acr_name != null ? var.acr_name : "${local.name_prefix}${random_string.acr_suffix.result}"
  acr_resource_group_name = var.acr_resource_group_name != null ? var.acr_resource_group_name : azurerm_resource_group.main.name
  frontdoor_endpoint_name = var.frontdoor_endpoint_name != null ? var.frontdoor_endpoint_name : "${local.name_prefix}-${random_string.fd_suffix.result}"
  acr_login_server        = var.use_existing_acr ? data.azurerm_container_registry.acr[0].login_server : azurerm_container_registry.acr[0].login_server
  acr_id                  = var.use_existing_acr ? data.azurerm_container_registry.acr[0].id : azurerm_container_registry.acr[0].id
  container_image         = "${local.acr_login_server}/${var.image_name}:${var.image_tag}"
}
