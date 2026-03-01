# =============================================================================
# modules/vm/variables.tf
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
  description = "Resource group to deploy VM into"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to attach the NIC to"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key content for VM authentication"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to all VM resources"
  type        = map(string)
  default     = {}
}
