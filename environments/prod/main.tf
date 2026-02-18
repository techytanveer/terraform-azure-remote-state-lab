terraform {
  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  common_tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}

module "resource_group" {
  source   = "../../modules/resource-group"
  name     = "rg-${var.project}-${var.environment}"
  location = var.location
  tags     = local.common_tags
}

module "storage" {
  source              = "../../modules/storage"
  name                = "st${var.project}${var.environment}001"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = local.common_tags
}
