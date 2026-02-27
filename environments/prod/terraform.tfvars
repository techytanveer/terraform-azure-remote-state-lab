# =============================================================================
# environments/prod/terraform.tfvars
# =============================================================================

project     = "azlab"
environment = "prod"
location    = "eastus"

# Network
vnet_address_space    = "10.0.0.0/16"
subnet_address_prefix = "10.0.1.0/24"
