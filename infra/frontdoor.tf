resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "${local.name_prefix}-fdp"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = local.frontdoor_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

resource "azurerm_cdn_frontdoor_origin_group" "main" {
  name                     = "${local.name_prefix}-og"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  session_affinity_enabled = false

  health_probe {
    interval_in_seconds = 120
    path                = "/"
    protocol            = "Https"
    request_type        = "GET"
  }

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }
}

resource "azurerm_cdn_frontdoor_origin" "primary" {
  name                           = "${local.name_prefix}-origin"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.main.id
  enabled                        = true
  certificate_name_check_enabled = true
  host_name                      = azurerm_container_app.primary.ingress[0].fqdn
  origin_host_header             = azurerm_container_app.primary.ingress[0].fqdn
  http_port                      = 80
  https_port                     = 443
  priority                       = 1
  weight                         = 100
}

resource "azurerm_cdn_frontdoor_origin" "secondary" {
  name                           = "${local.name_prefix}-origin2"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.main.id
  enabled                        = true
  certificate_name_check_enabled = true
  host_name                      = azurerm_container_app.secondary.ingress[0].fqdn
  origin_host_header             = azurerm_container_app.secondary.ingress[0].fqdn
  http_port                      = 80
  https_port                     = 443
  priority                       = 2
  weight                         = 100
}

resource "azurerm_cdn_frontdoor_route" "main" {
  name                          = "${local.name_prefix}-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id
  cdn_frontdoor_origin_ids = [
    azurerm_cdn_frontdoor_origin.primary.id,
    azurerm_cdn_frontdoor_origin.secondary.id
  ]

  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
  forwarding_protocol    = "HttpsOnly"
  link_to_default_domain = true
  https_redirect_enabled = true
}
