# =============================================================================
# modules/network/variables.tf
# =============================================================================

variable "project" {
  description = "Project short name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name: dev or prod"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy network resources into"
  type        = string
}

variable "vnet_address_space" {
  description = "CIDR block for the Virtual Network (e.g. 10.0.0.0/16)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_address_prefix" {
  description = "CIDR block for the web subnet (e.g. 10.0.1.0/24)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "tags" {
  description = "Tags to apply to all network resources"
  type        = map(string)
  default     = {}
}
