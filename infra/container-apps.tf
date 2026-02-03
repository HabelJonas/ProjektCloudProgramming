resource "azurerm_container_app" "primary" {
  name                         = "${local.name_prefix}-app1"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.primary.id
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_identity.id]
  }

  registry {
    server   = local.acr_login_server
    identity = azurerm_user_assigned_identity.app_identity.id
  }

  template {
    revision_suffix = var.image_revision

    container {
      name   = "web"
      image  = local.container_image
      cpu    = 0.25
      memory = "0.5Gi"
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    http_scale_rule {
      name                = "http"
      concurrent_requests = 50
    }
  }

  ingress {
    external_enabled = true
    target_port      = var.container_port

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

resource "azurerm_container_app" "secondary" {
  name                         = "${local.name_prefix}-app2"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.secondary.id
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_identity.id]
  }

  registry {
    server   = local.acr_login_server
    identity = azurerm_user_assigned_identity.app_identity.id
  }

  template {
    revision_suffix = var.image_revision

    container {
      name   = "web"
      image  = local.container_image
      cpu    = 0.25
      memory = "0.5Gi"
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    http_scale_rule {
      name                = "http"
      concurrent_requests = 50
    }
  }

  ingress {
    external_enabled = true
    target_port      = var.container_port

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
