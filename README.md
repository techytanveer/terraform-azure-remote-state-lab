[![Terraform Plan](https://github.com/techytanveer/terraform-azure-remote-state-lab/actions/workflows/terraform-plan.yml/badge.svg)](https://github.com/techytanveer/terraform-azure-remote-state-lab/actions/workflows/terraform-plan.yml)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat-square&logo=github&logoColor=white)](https://github.com)
[![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=flat-square&logo=terraform&logoColor=white)](https://www.terraform.io)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=flat-square&logo=ubuntu&logoColor=white)](https://ubuntu.com)
[![Azure](https://img.shields.io/badge/Azure-0078D4?style=flat-square&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-enabled-orange?logo=anthropic)](https://code.claude.com)


# terraform-azure-remote-state-lab

A hands-on Terraform lab using **Azure Blob Storage as a remote state backend** — with a production-grade project structure.

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

## Project Phases

- **Phase 1 ✅: Terraform Foundation — Remote State, Modular IaC & CI on Azure**
- **Phase 2 ✅: Add terraform apply to prod only on merge to main — full GitOps flow**
- **Phase 3 🔄: Add a Virtual Network + Subnet — classic IaC exercise** 
- **Phase 4 🔄: Add a Linux VM (Standard_B1s — free tier eligible)**
- **Phase 5 🔄: Add Azure Key Vault — store secrets properly**

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

# Phase 1 - Implementation 

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

**Creating a Service Principle**

```
# Grab subscription ID
export SUB_ID=$(az account show --query id -o tsv)
echo "Subscription: $SUB_ID"

# Creating SP with Contributor role
az ad sp create-for-rbac \
  --name "terraform-sp" \
  --role Contributor \
  --scopes /subscriptions/$SUB_ID \
  --output json

OUTPUT:

{
  "appId": "8aa8dcef-0e29-488b-a3fc-7a0706aedd14",
  "displayName": "terraform-sp",
  "password": "XXXXXXXXXXXXXXXXXXXXXXXXXXXX",
  "tenant": "7de7f4e3-6402-4f4e-8c2b-c3f55636d41d"
}


```

**Setting Credentials**

```
cat >> ~/.bashrc << 'EOF'

# Azure / Terraform credentials
export ARM_SUBSCRIPTION_ID="<your-subscription-id>"
export ARM_TENANT_ID="<tenant>"
export ARM_CLIENT_ID="<appId>"
export ARM_CLIENT_SECRET="<password>"
EOF

source ~/.bashrc

ENABLE AUTOCOMPLETE
# Terraform
terraform -install-autocomplete

# Azure CLI
echo 'source /etc/bash_completion.d/azure-cli' >> ~/.bashrc
source ~/.bashrc
```

**GitHub Setup**
```
...1)

cd terraform-azure-remote-state-lab
git init
git add .
git commit -m "initial: terraform-azure-remote-state-lab scaffold"
gh repo create terraform-azure-remote-state-lab --public
git remote add origin git@github.com:techytanveer/terraform-azure-remote-state-lab.git
git branch -M main
git push -u origin main
gh run list

...2)

Add GitHub Secrets (for CI to work) under Settings > Secrets > Actions:

ARM_SUBSCRIPTION_ID
ARM_TENANT_ID
ARM_CLIENT_ID
ARM_CLIENT_SECRET
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
  "tenantDefaultDomain": "tanveerXXXXXXXXXX.onmicrosoft.com",
  "tenantDisplayName": "Default Directory",
  "tenantId": "7de7f4e3-6402-4f4e-8c2b-c3f55636d41d", "user": {
    "name": "tanveer_XXXXXX@XXXXX.com",
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

**Crosscheck STORAGE ACCOUNT**
```
az storage account list --output table
AccessTier    AllowBlobPublicAccess    AllowCrossTenantReplication    CreationTime                      EnableHttpsTrafficOnly    Kind       Location    MinimumTlsVersion    Name             PrimaryLocation    ProvisioningState    ResourceGroup    StatusOfPrimary
------------  -----------------------  -----------------------------  --------------------------------  ------------------------  ---------  ----------  -------------------  ---------------  -----------------  -------------------  ---------------  -----------------
Hot           False                    False                          2026-02-19T03:27:09.050621+00:00  True                      StorageV2  eastus      TLS1_0               tfstateyq2wlh1p  eastus             Succeeded            rg-tfstate       available

```
## Post-Creation - Environmental Setup

**Current Status**

✅ Resource Group  : rg-tfstate

✅ Storage Account : tfstateyq2wlh1p

✅ Blob Versioning : enabled (isVersioningEnabled: true)

✅ Container       : tfstate  ("created": true)


**Updating backend.tf Files & Verifying**

```
# Do this from project root
sed -i 's/REPLACE_WITH_STORAGE_ACCOUNT/tfstateyq2wlh1p/g' \
  environments/dev/backend.tf \
  environments/prod/backend.tf

cat environments/dev/backend.tf
cat environments/prod/backend.tf
```

**Creating the Service Principle**

```
az ad sp create-for-rbac \
  --name "terraform-sp" \
  --role Contributor \
  --scopes /subscriptions/a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d \
  --output json


{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "displayName": "terraform-sp",
  "password": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenant": "7de7f4e3-6402-4f4e-8c2b-c3f55636d41d"
}
```

**Saving it locally to a secure file:**

```
# Create a secure file only you can read
touch ~/.azure/terraform-sp.json
chmod 600 ~/.azure/terraform-sp.json

# Then paste the SP output into it
vi ~/.azure/terraform-sp.json
```

```
Both `hbackend.tf` files are correctly updated. Notice the only difference between dev and prod is the `key`:

dev  → key = "dev/terraform.tfstate"
prod → key = "prod/terraform.tfstatea"
```

**Terraform environment variables:**


| SP Output | Environment Variable |
| --------- | --------------------
| `appId` | `ARM_CLIENT_ID` |
| `password` | `ARM_CLIENT_SECRET` |
| `tenant` | `ARM_TENANT_ID` |

**Setting Environment variables:**

```
export ARM_SUBSCRIPTION_ID="a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d"
export ARM_TENANT_ID=$(cat ~/.azure/terraform-sp.json | grep tenant | awk -F'"' '{print $4}')
export ARM_CLIENT_ID=$(cat ~/.azure/terraform-sp.json | grep appId | awk -F'"' '{print $4}')
export ARM_CLIENT_SECRET=$(cat ~/.azure/terraform-sp.json | grep password | awk -F'"' '{print $4}')
```

**Add to `~/.bashrc` to persist across sessions:**

```
cat >> ~/.bashrc << 'EOF'

# Azure Terraform credentials
export ARM_SUBSCRIPTION_ID="a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d"
export ARM_TENANT_ID="<paste-tenant>"
export ARM_CLIENT_ID="<paste-appId>"
export ARM_CLIENT_SECRET="<paste-password>"
EOF
source ~/.bashrc
```

**Verifying variables are set:**

```
echo "SUB: $ARM_SUBSCRIPTION_ID"
echo "TEN: $ARM_TENANT_ID"
echo "CLI: $ARM_CLIENT_ID"
echo "SEC: ${ARM_CLIENT_SECRET:0:4}****"   # shows only first 4 chars
```
## Applying Stage - Development Environment

```
cd ~/terraform-azure-remote-state-lab/environments/dev

terraform init
```

Above Action:

1. Download the `azurerm` provider
2. Connect to your Azure Blob Storage backend
3. Create `dev/terraform.tfstate` in the blob container

**After init Success**

```
terraform plan
```

**Checks prior apply**

```
Plan: 2 to add, 0 to change, 0 to destroy
```
Both with tags:
```
environment = "dev"
managed_by  = "terraform"
project     = "azlab"
```
**Notice at the bottom:**

✅ "Releasing state lock" — confirms blob backend is working perfectly

**Apply**

```
terraform apply
```

**Check 4 outputs in above**

✅ resource_group_name     = "rg-azlab-dev"

✅ resource_group_location = "eastus"

✅ storage_account_name    = "stazlabdev001"

✅ storage_blob_endpoint   = "https://stazlabdev001.blob.core.windows.net/"

**What Just Happened**

```
At My Local Dev (Ubuntu) Machine
      │
      ├─► terraform apply
      │         │
      │         ├─► State locked   in Azure Blob (tfstateyq2wlh1p)
      │         ├─► Created        rg-azlab-dev
      │         ├─► Created        stazlabdev001
      │         ├─► State saved    in Azure Blob (dev/terraform.tfstate)
      │         └─► State unlocked
```

**Verifying at Azure**

```
~/terraform-azure-remote-state-lab$ az resource list --resource-group rg-azlab-dev --output table
Name           ResourceGroup    Location    Type                               Status
-------------  ---------------  ----------  ---------------------------------  ---------
stazlabdev001  rg-azlab-dev     eastus      Microsoft.Storage/storageAccounts  Succeeded
~/terraform-azure-remote-state-lab$
```

**Preparing Git Push**

Adding at GitHub Actions secrets under `Settings` → `Secrets` → `Actions`:

| Secret | Value |
| ------ | ----- |
| `ARM_SUBSCRIPTION_ID` | `a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d` |
| `ARM_TENANT_ID` | `7de7f4e3-6402-4f4e-8c2b-c3f55636d41d` |
| `ARM_CLIENT_ID` | `appId` |
| `ARM_CLIENT_SECRET` | `password` |

OR adding via CLI

```
gh secret set ARM_SUBSCRIPTION_ID --body "a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d"
gh secret set ARM_TENANT_ID --body "7de7f4e3-6402-4f4e-8c2b-c3f55636d41d"
gh secret set ARM_CLIENT_ID --body "<appId>"
gh secret set ARM_CLIENT_SECRET --body "<password>"

gh secret list
```

**Git Push**

```
cd ~/terraform-azure-remote-state-lab
git init
git add .
git commit -m "initial: terraform-azure-remote-state-lab with Azure blob backend"
git push origin main
```

## Applying Stage - Prodution Environment

**Repeating above steps, but not all because env variables are set, for Production environment**

```
~$ cd ~/terraform-azure-remote-state-lab/environments/prod/
$terraform init
$terraform plan

Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + resource_group_location = "eastus"
  + resource_group_name     = "rg-azlab-prod"
  + storage_account_name    = "stazlabprod001"
  + storage_blob_endpoint   = (known after apply)

$terraform apply

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

resource_group_location = "eastus"
resource_group_name = "rg-azlab-prod"
storage_account_name = "stazlabprod001"
storage_blob_endpoint = "https://stazlabprod001.blob.core.windows.net/"
 
~/terraform-azure-remote-state-lab/environments/prod$ az resource list --resource-gro
up rg-azlab-dev --output table
Name           ResourceGroup    Location    Type                               Status
-------------  ---------------  ----------  ---------------------------------  ------
---
stazlabdev001  rg-azlab-dev     eastus      Microsoft.Storage/storageAccounts  Succee
ded
~/terraform-azure-remote-state-lab/environments/prod$

$git add .
$git commit -m "initial: adding production resource"
$git push origin main
```

## Knowledgebase: Running CI/CD Empty Workflow

**There are two ways**

1. Commit

```
git commit --allow-empty -m "chore: trigger CI to verify prod state sync"
git push
git run watch
```
2. workflow_dispatch

```
# Edit the workflow file
vi .github/workflows/terraform-plan.yml

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
  workflow_dispatch: <<<<< Add this line

git add .github/workflows/terraform-plan.yml
git commit -m "ci: add workflow_dispatch for manual triggers"
git push

After this push the workflow will run automatically, and from now on we can also trigger it manually anytime with `gh workflow run terraform-plan.yml` — no empty commits needed.

```

### Summary of everything accomplished as of now:

**What was built**

```
terraform-azure-remote-state-lab/
├── Modular Terraform structure        ✅
├── Azure Blob remote state backend    ✅
├── Dev environment (applied)          ✅
├── Prod environment (applied)         ✅
└── GitHub Actions CI pipeline         ✅
```
**Azure Resources Live**

| Resource | Name | Environment | 
| -------- | ---- | ----------- |
| Resource Group | `rg-tfstate` | backend |
| Storage Account | `tfstateyq2wlh1p` | backend (state) |
| Resource Group | `rg-azlab-dev` | dev | 
| Storage Account | `stazlabdev001` | dev |
| Resource Group | `rg-azlab-prod` | prod |
| Storage Account | `stazlabprod001` | prod |

**Key Concepts Practiced**

- Azure provider authentication via Service Principal
- Remote state with blob backend and state locking
- Modular Terraform with reusable `modules/`
- Isolated dev/prod environments sharing one backend
- GitHub Actions CI running `plan` on every push
- Manual workflow dispatch trigger

---

# Phase 2 - Implementation

**The Full GitOps Flow We're Building**

```
Developer                GitHub                        Azure
─────────                ──────                        ──────
git push feature ──►  PR opened
                          │
                          ├──► Plan (dev)   runs ──►  reads dev state
                          ├──► Plan (prod)  runs ──►  reads prod state
                          │         │
                          │    PR reviewed & merged to main
                          │
                          └──► Apply (prod) runs ──►  applies to Azure
                                                       writes prod state
```

**One caveat** — the required reviewers protection rule on environments only works on **public repos or GitHub Pro/Team accounts**. Since my repo is public it should work fine.

**What We Need to Change**

**Current workflow** — triggers on push + PR:

- `terraform plan` for dev ✅
- `terraform plan` for prod ✅

**New workflow** — triggers only on merge to main:

- `terraform apply` for prod only ✅
- With manual approval gate (so prod never applies <ins>accidentally</ins>) ✅

**Two Files to Create/Modify**

1. **Modify** `.github/workflows/terraform-plan.yml` — restrict to PRs only (not push to main)
2. **Create** `.github/workflows/terraform-apply-prod.yml` — new, triggers on merge to main with approval gate

**GitHub Environment Setup (required for approval gate)**

The approval gate lives in a GitHub Environment called `production`. We need to create it first.

Go to your repo:

```
https://github.com/techytanveer/terraform-azure-remote-state-lab
→ Settings
→ Environments
→ New environment
→ Name: production
→ Add required reviewers: techytanveer (myself)
→ Save protection rules
```

**OR via CLI**

Here's the CLI way using the GitHub API:

```
# Step 1 - Create the 'production' environment

gh api \
  --method PUT \
  /repos/techytanveer/terraform-azure-remote-state-lab/environments/production

# Step 2 - Get your user ID (needed for reviewer)

gh api /user --jq '.id'
```
Paste the user ID output, then run Step 3 with it:

```
# Step 3 - Add yourself as required reviewer (replace USER_ID with output from above)
gh api \
  --method PUT \
  /repos/techytanveer/terraform-azure-remote-state-lab/environments/production \
  --field "reviewers[][type]=User" \
  --field "reviewers[][id]=USER_ID" \
  --field "wait_timer=0"
```

Then verify it was created correctly:

```
gh api /repos/techytanveer/terraform-azure-remote-state-lab/environments \
  --jq '.environments[].name'

~/terraform-azure-remote-state-lab$ gh api /repos/techytanveer/terraform-azure-remote-state-lab/environments \
  --jq '.environments[].name'
production
~/terraform-azure-remote-state-lab$


```

One must see `production` listed above.

---

# Phase 3 - Implementation 

**What We're Building**

- VNet + Subnet be deployed at Dev first, then promote to `prod` via PR
- 1 Subnet to start with
- Production-grade approach via adding Network Security Groups NSG to Subnet

```
modules/
└── network/
    ├── main.tf        ← VNet + Subnet + NSG + NSG Association
    ├── variables.tf
    └── outputs.tf

environments/
└── dev/
    ├── main.tf        ← add network module call
    ├── variables.tf   ← add network variables
    ├── outputs.tf     ← add network outputs
    └── terraform.tfvars ← add network values
```

**Resource Design**

```
VNet: 10.0.0.0/16  (vnet-azlab-dev)
  └── Subnet: 10.0.1.0/24  (snet-web-azlab-dev)
        └── NSG: nsg-web-azlab-dev
              ├── Allow HTTPS inbound  (port 443)
              ├── Allow HTTP inbound   (port 80)
              └── Deny all inbound     (default catch-all)
```

**GitOps Flow**

```
feature/add-network branch
        │
        └──► PR to main
                │
                ├──► Plan (dev)  ← shows 4 resources to add
                ├──► Plan (prod) ← shows 0 changes
                │
                └──► Merge to main
                          │
                          └──► Approval gate ──► Apply (prod)
```


---

# Phase 4 -

---

# Phase 5 -

---

# Phase 6 -

---
