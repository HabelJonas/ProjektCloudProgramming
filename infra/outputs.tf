output "acr_name" {
  value       = local.acr_name
  description = "Azure Container Registry name."
}

output "acr_login_server" {
  value       = local.acr_login_server
  description = "Azure Container Registry login server."
}

output "container_app_primary_fqdn" {
  value       = azurerm_container_app.primary.ingress[0].fqdn
  description = "Primary Container App FQDN."
}

output "container_app_secondary_fqdn" {
  value       = azurerm_container_app.secondary.ingress[0].fqdn
  description = "Secondary Container App FQDN."
}

output "frontdoor_endpoint_host" {
  value       = azurerm_cdn_frontdoor_endpoint.main.host_name
  description = "Front Door endpoint hostname."
}

output "frontdoor_url" {
  value       = "https://${azurerm_cdn_frontdoor_endpoint.main.host_name}"
  description = "Front Door endpoint URL."
}
