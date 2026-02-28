# =============================================================================
# modules/vm/outputs.tf
# =============================================================================

output "vm_id" {
  description = "Virtual Machine resource ID"
  value       = azurerm_linux_virtual_machine.this.id
}

output "vm_name" {
  description = "Virtual Machine name"
  value       = azurerm_linux_virtual_machine.this.name
}

output "public_ip" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.this.ip_address
}

output "private_ip" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.this.private_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh -i ~/.ssh/id_rsa_azure ${azurerm_linux_virtual_machine.this.admin_username}@${azurerm_public_ip.this.ip_address}"
}
