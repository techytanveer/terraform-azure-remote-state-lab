# =============================================================================
# environments/dev/outputs.tf
# =============================================================================

output "resource_group_name" {
  description = "Name of the deployed resource group"
  value       = module.resource_group.name
}

output "resource_group_location" {
  description = "Location of the deployed resource group"
  value       = module.resource_group.location
}

output "storage_account_name" {
  description = "Name of the deployed storage account"
  value       = module.storage.name
}

output "storage_blob_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = module.storage.primary_blob_endpoint
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = module.network.vnet_name
}

output "vnet_id" {
  description = "Resource ID of the Virtual Network"
  value       = module.network.vnet_id
}

output "subnet_name" {
  description = "Name of the web subnet"
  value       = module.network.subnet_name
}

output "nsg_name" {
  description = "Name of the Network Security Group"
  value       = module.network.nsg_name
}
