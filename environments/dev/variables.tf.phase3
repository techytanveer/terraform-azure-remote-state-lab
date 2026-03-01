# =============================================================================
# environments/dev/variables.tf
# =============================================================================

variable "project" {
  description = "Project short name used in resource naming (lowercase, no spaces)"
  type        = string
}

variable "environment" {
  description = "Environment name: dev or prod"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "eastus"
}

variable "vnet_address_space" {
  description = "CIDR block for the Virtual Network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_address_prefix" {
  description = "CIDR block for the web subnet"
  type        = string
  default     = "10.0.1.0/24"
}

