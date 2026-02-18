# terraform-azure-remote-state-lab

A hands-on Terraform lab using **Azure Blob Storage as a remote state backend** — going beyond the free-tier default local state, with a production-grade project structure.

## What This Lab Covers

- Azure provider setup and authentication via Service Principal
- Remote state backend using **Azure Blob Storage** (not local)
- State locking to prevent concurrent `apply` conflicts
- Modular Terraform structure (`modules/`)
- Separate `dev` and `prod` environments
- GitHub Actions CI pipeline for `terraform plan`

## Tech Stack

| Tool | Version |
|------|---------|
| Terraform | >= 1.6 |
| Azure Provider (azurerm) | ~> 3.0 |
| Azure CLI | latest |
| OS | Ubuntu 24.04 LTS |

## Prerequisites

- Azure account (free tier with $200 credit works fine)
- Azure CLI installed and logged in
- Terraform installed
- Service Principal created with Contributor role

## Project Structure

```
terraform-azure-remote-state-lab/
├── README.md
├── .gitignore
├── .github/
│   └── workflows/
│       └── terraform-plan.yml       # CI: runs terraform plan on PR
├── scripts/
│   └── bootstrap.sh                 # One-time: creates blob storage backend
├── modules/
│   ├── resource-group/              # Reusable resource group module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── storage/                     # Reusable storage account module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    ├── dev/                         # Dev environment
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   ├── terraform.tfvars
    │   └── backend.tf               # Points to Azure Blob backend
    └── prod/                        # Prod environment
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        ├── terraform.tfvars
        └── backend.tf
```

## Quick Start

### 1. Bootstrap the Remote State Backend (one-time)

```bash
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh
```

This creates the Azure Storage Account and container that Terraform will use to store state.

### 2. Set Environment Variables

```bash
export ARM_SUBSCRIPTION_ID="<your-subscription-id>"
export ARM_TENANT_ID="<your-tenant-id>"
export ARM_CLIENT_ID="<your-app-id>"
export ARM_CLIENT_SECRET="<your-password>"
```

### 3. Deploy Dev Environment

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

### 4. Destroy When Done (to save credits)

```bash
terraform destroy
```

## Why Remote State?

| | Local State | Azure Blob Backend |
|---|---|---|
| Safe if laptop dies | ❌ | ✅ |
| Team collaboration | ❌ | ✅ |
| State locking | ❌ | ✅ |
| State versioning | ❌ | ✅ |
| Cost | Free | ~$0.01/month |

## Author

Built on Ubuntu 24.04 LTS · Azure Free Tier ($200 credit)

## Installation

**Azure CLI Installation**

```
# Ubuntu/Debian
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# RHEL/Oracle Linux
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf install azure-cli
```

**Terraform Installation**
```
# Ubuntu
sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# RHEL/Oracle Linux
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum install terraform
```

**Azure Cloud Login**

```
~/terraform-azure-remote-state-lab$ az login
To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code JY8A9KAH6 to authenticate.

Retrieving tenants and subscriptions for the selection...

[Tenant and subscription selection]

No     Subscription name     Subscription ID                       Tenant
-----  --------------------  ------------------------------------  -----------------
[1] *  Azure subscription 1  a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d  Default Directory

The default is marked with an *; the default tenant is 'Default Directory' and subscription is 'Azure subscription 1' (a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d).

Select a subscription and tenant (Type a number or Enter for no changes):

Tenant: Default Directory
Subscription: Azure subscription 1 (a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d)

[Announcements]
With the new Azure CLI login experience, you can select the subscription you want to use more easily. Learn more about it and its configuration at https://go.microsoft.com/fwlink/?linkid=2271236

If you encounter any problem, please open an issue at https://aka.ms/azclibug

[Warning] The login output has been updated. Please be aware that it no longer displays the full list of available subscriptions by default.


```

**Azure Account**

```
~/terraform-azure-remote-state-lab$ az account show
{
  "environmentName": "AzureCloud",
  "homeTenantId": "7de7f4e3-6402-4f4e-8c2b-c3f55636d41d",
  "id": "a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d",
  "isDefault": true,
  "managedByTenants": [],
  "name": "Azure subscription 1",
  "state": "Enabled",
  "tenantDefaultDomain": "tanveerahmedlive.onmicrosoft.com",
  "tenantDisplayName": "Default Directory",
  "tenantId": "7de7f4e3-6402-4f4e-8c2b-c3f55636d41d",
  "user": {
    "name": "tanveer_ahmed@live.com",
    "type": "user"
  }
}
~/terraform-azure-remote-state-lab$
~/terraform-azure-remote-state-lab$ az account list --output table
Name                  CloudName    SubscriptionId                        TenantId                              State    IsDefault
--------------------  -----------  ------------------------------------  ------------------------------------  -------  -----------
Azure subscription 1  AzureCloud   a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d  7de7f4e3-6402-4f4e-8c2b-c3f55636d41d  Enabled  True
~/terraform-azure-remote-state-lab$
```
