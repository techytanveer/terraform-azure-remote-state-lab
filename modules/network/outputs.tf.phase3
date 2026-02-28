# =============================================================================
# modules/network/outputs.tf
# =============================================================================

output "vnet_id" {
  description = "Virtual Network resource ID"
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Virtual Network name"
  value       = azurerm_virtual_network.this.name
}

output "subnet_id" {
  description = "Web subnet resource ID"
  value       = azurerm_subnet.web.id
}

output "subnet_name" {
  description = "Web subnet name"
  value       = azurerm_subnet.web.name
}

output "nsg_id" {
  description = "Network Security Group resource ID"
  value       = azurerm_network_security_group.web.id
}

output "nsg_name" {
  description = "Network Security Group name"
  value       = azurerm_network_security_group.web.name
}
