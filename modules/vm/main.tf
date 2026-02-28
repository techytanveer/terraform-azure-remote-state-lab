# =============================================================================
# modules/vm/main.tf
# Creates: Public IP, NIC, RHEL 9 VM (Standard_D2s_v3 - free tier eligible)
# =============================================================================

resource "azurerm_public_ip" "this" {
  name                = "pip-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["3"]
  tags                = var.tags
}

resource "azurerm_network_interface" "this" {
  name                = "nic-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  depends_on          = [var.subnet_id]

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  name                            = "vm-${var.project}-${var.environment}"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = "Standard_D2s_v3"
  admin_username                  = var.admin_username
  disable_password_authentication = true
  zone                            = "3"
  tags                            = var.tags

  network_interface_ids = [
    azurerm_network_interface.this.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "osdisk-${var.project}-${var.environment}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  # Ubuntu 24.04
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # Auto-shutdown at midnight to save credits
  lifecycle {
    ignore_changes = [
      tags["last_started"]
    ]
  }
}
