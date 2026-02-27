# =============================================================================
# environments/dev/backend.tf
# =============================================================================

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstateyq2wlh1p"
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate"
  }
}
