terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "REPLACE_WITH_STORAGE_ACCOUNT"
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate"
  }
}
