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

variable "admin_ip_cidr" {
  description = "Your public IP in CIDR notation for SSH access (e.g. 1.2.3.4/32)"
  type        = string
  sensitive   = true

  validation {
    condition     = can(cidrnetmask(var.admin_ip_cidr))
    error_message = "Must be a valid CIDR block e.g. 1.2.3.4/32"
  |
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
