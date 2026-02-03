variable "project_name" {
  type        = string
  description = "Base name used for Azure resources."
  default     = "cloudprogramming"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name."
  default     = "rg-cloudprogramming"
}

variable "location_primary" {
  type        = string
  description = "Primary Azure region."
  default     = "westeurope"
}

variable "location_secondary" {
  type        = string
  description = "Secondary Azure region."
  default     = "northeurope"
}

variable "image_name" {
  type        = string
  description = "Container image name (repository) in ACR."
  default     = "cloudprogramming-app"
}

variable "image_tag" {
  type        = string
  description = "Container image tag to deploy."
  default     = "latest"
}

variable "image_revision" {
  type        = string
  description = "Revision suffix to force new Container App revisions even when tag is unchanged."
  default     = null
}

variable "container_port" {
  type        = number
  description = "Port exposed by the container."
  default     = 80
}

variable "min_replicas" {
  type        = number
  description = "Minimum number of replicas for each Container App."
  default     = 1
}

variable "max_replicas" {
  type        = number
  description = "Maximum number of replicas for each Container App."
  default     = 10
}

variable "acr_name" {
  type        = string
  description = "Optional ACR name override (lowercase alphanumeric, 5-50 chars)."
  default     = null

  validation {
    condition     = var.acr_name == null || can(regex("^[a-z0-9]{5,50}$", var.acr_name))
    error_message = "If provided, acr_name must be 5-50 lowercase letters/numbers only."
  }
  validation {
    condition     = var.use_existing_acr == false || var.acr_name != null
    error_message = "When use_existing_acr is true, acr_name must be provided."
  }
}

variable "use_existing_acr" {
  type        = bool
  description = "Use an existing Azure Container Registry instead of creating one."
  default     = false
}

variable "acr_resource_group_name" {
  type        = string
  description = "Resource group name for an existing ACR (defaults to the main resource group)."
  default     = null
}

variable "frontdoor_endpoint_name" {
  type        = string
  description = "Optional Front Door endpoint name override (lowercase alphanumeric or hyphen, 2-64 chars)."
  default     = null

  validation {
    condition     = var.frontdoor_endpoint_name == null || can(regex("^[a-z0-9-]{2,64}$", var.frontdoor_endpoint_name))
    error_message = "If provided, frontdoor_endpoint_name must be 2-64 lowercase letters, numbers, or hyphens."
  }
}
