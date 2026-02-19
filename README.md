[![Terraform Plan](https://github.com/techytanveer/terraform-azure-remote-state-lab/actions/workflows/terraform-plan.yml/badge.svg)](https://github.com/techytanveer/terraform-azure-remote-state-lab/actions/workflows/terraform-plan.yml)

![Terraform](https://img.shields.io)
![Ubuntu](https://img.shields.io)
![Azure](https://img.shields.io)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-enabled-orange?logo=anthropic)](https://code.claude.com)
[![Built with Claude](https://img.shields.io/badge/built%20with-Claude%20Code-blueviolet)](https://code.claude.com)

# terraform-azure-remote-state-lab

**(This project is at initial phase)**

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

- Azure account
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

```
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh
```

This creates the Azure Storage Account and container that Terraform will use to store state.

### 2. Set Environment Variables

```
export ARM_SUBSCRIPTION_ID="<your-subscription-id>"
export ARM_TENANT_ID="<your-tenant-id>"
export ARM_CLIENT_ID="<your-app-id>"
export ARM_CLIENT_SECRET="<your-password>"
```

### 3. Deploy Dev Environment

```
cd environments/dev
terraform init
terraform plan
terraform apply
```

### 4. Destroy When Done (to save credits)

```
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

Built on Ubuntu 24.04 LTS · Azure 

---

# Installation User Guide

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

**Authenticate Azure Account**

```
az account set --subscription "a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d"
```

**Register the providers**

```
az provider register --namespace Microsoft.Storage --subscription "a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d"
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.KeyVault

```

**Verify registeration of all providers**
It should say 'registerd', keep on checking while 'registering'

```
az provider show --namespace Microsoft.Storage | grep -i registrationState
  "registrationState": "Registered",


for ns in Microsoft.Network Microsoft.Compute Microsoft.KeyVault; do   echo -n "$ns: ";   az provider show --namespace $ns --query "registrationState" --output tsv; done
Microsoft.Network:
Registered
Microsoft.Compute:
Registered
Microsoft.KeyVault:
Registered
```
**Subscription ID, App ID, Tenant ID and others**
Note down IDs from these outputs
```
az account set --subscription "a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d"

az account show --output table

az account show --query "{SubscriptionID:id, TenantID:tenantId, Name:name}" --output table

az account show --query id --output tsv

ALSO, set:
RESOURCE_GROUP="rg-tfstate"
LOCATION="eastaus"
CONTAINER="tfstate"

STORAGE_ACCOUNT="tfstate$(cat /dev/urandom | tr -dc 'a-z0-9' | head -c 8)"

```
**The scripts/bootstrap.sh script**
```
RESOURCE_GROUP="rg-tfstate"
LOCATION="eastus"
STORAGE_ACCOUNT="tfstateyq2wlh1p"   # reuse the one already generated
CONTAINER="tfstate"
SUBSCRIPTION="a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d"

# Step 0 - Re-authenticate first
az account set --subscription "$SUBSCRIPTION"

# Step 1 - Resource group
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

# Step 2 - Storage account
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --allow-blob-public-access false \
  --subscription "$SUBSCRIPTION"

# Step 3 - Enable versioning
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --enable-versioning true \
  --subscription "$SUBSCRIPTION"

# Step 4 - Create container
az storage container create \
  --name "$CONTAINER" \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login \
  --subscription "$SUBSCRIPTION"

echo "Done! Storage account: $STORAGE_ACCOUNT"

```

