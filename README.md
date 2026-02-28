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
│       └── terraform-plan.yml       # CI: runs terraform plan on PR only (not push to main)
│       └── terraform-apply-prod.yml # CI: runs terraform plan on PR (on merge, approval gate)
├── scripts/
│   └── bootstrap.sh                 # One-time: creates blob storage backend
├── modules/
│   ├── keyvault/                    # Azure Key Vault & access policy
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── vm/                          # Public IP, NIC, RHEL 9 VM module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── network/                     # VNet + subnet + NSG + NSG Association module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
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
- **Phase 2 ✅: Terraform apply to prod only on merge to main — full GitOps flow**
- **Phase 3 ✅: Adding a Virtual Network + Subnet — classic IaC exercise / GitOps in Action — Feature Branch → PR → Approval Gate → Prod Apply** 
- **Phase 4 ✅: Add a Linux VM in Dev environment (Standard_D2s_v3 - 2 vcpus, 8 GiB memory ($70.08/month) zone 3 of (US) West US 3)**
- **Phase 5 🔄: Adding Azure Key Vault — store secrets properly**
- **Phase 6 🔄: Azure Ops hands-on via CLI**
- **Phase 7 🔄: Moving VM to Production from Dev**

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

- **Remote State** — the headline feature
- **Modular IaC** — shows structure and best practices
- **CI on Azure** — shows automation maturity

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

```
✅ Resource Group  : rg-tfstate
✅ Storage Account : tfstateyq2wlh1p
✅ Blob Versioning : enabled (isVersioningEnabled: true)
✅ Container       : tfstate  ("created": true)
```


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

```
✅ resource_group_name     = "rg-azlab-dev"
✅ resource_group_location = "eastus"
✅ storage_account_name    = "stazlabdev001"
✅ storage_blob_endpoint   = "https://stazlabdev001.blob.core.windows.net/"
```

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

**The Full GitOps Flow We're Building:**

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

**What We Need to Change:**

**Current workflow** — triggers on push + PR:

- `terraform plan` for dev ✅
- `terraform plan` for prod ✅

**New workflow** — triggers only on merge to main:

- `terraform apply` for prod only ✅
- With manual approval gate (so prod never applies <ins>accidentally</ins>) ✅

**Two Files to Create/Modify:**

1. **Modify** `.github/workflows/terraform-plan.yml` — restrict to PRs only (not push to main)
2. **Create** `.github/workflows/terraform-apply-prod.yml` — new, triggers on merge to main with approval gate

**GitHub Environment Setup (required for approval gate):**

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

# Phase 3 - Implementation (GitOps in Action — Feature Branch → PR → Approval Gate → Prod Apply)

**What We're Building:**

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

**Resource Design:**

```
VNet: 10.0.0.0/16  (vnet-azlab-dev)
  └── Subnet: 10.0.1.0/24  (snet-web-azlab-dev)
        └── NSG: nsg-web-azlab-dev
              ├── Allow HTTPS inbound  (port 443)
              ├── Allow HTTP inbound   (port 80)
              └── Deny all inbound     (default catch-all)
```

**GitOps Flow:**

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

**Pre-Checks:**

```
gh run list --workflow=terraform-apply-prod.yml

Creating a feature branch

git checkout -b feature/add-network
```

**Updating Project Files:**

```
# From project root, on feature/add-network branch
cd ~/terraform-azure-remote-state-lab

# Create network module directory
mkdir -p modules/network

# Creating module files
modules/network/main.tf
modules/network/variables.tf
modules/network/outputs.tf

# Modifying dev environment files
environments/dev/main.tf
environments/dev/variables.tf
environments/dev/terraform.tfvars
environments/dev/outputs.tf

# Verifying all files
find modules/network -type f | sort
cat modules/network/main.tf

```

**Setting ARM Credentials for this session, if session expired earlier:**

```
export ARM_SUBSCRIPTION_ID="a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d"
export ARM_TENANT_ID="7de7f4e3-6402-4f4e-8c2b-c3f55636d41d"
export ARM_CLIENT_ID="8aa8dcef-0e29-488b-a3fc-7a0706aedd14"
export ARM_CLIENT_SECRET="<password>"

To load on every new terminal:

vi ~/.bashrc

# Add the 4 ARM_ exports at the bottom
source ~/.bashrc
```

**Testing Locally:**

```
cd environments/dev
terraform init    # needed to pick up new network module
terraform plan
```
We should see `Plan: 4 to add` — the VNet, Subnet, NSG, and NSG Association.

**Error: IPv6 conflict - curl is trying IPv6 addresses first and failing**

```
CHECKS - if IPv6 causing issue:

# Check DNS resolution
nslookup registry.terraform.io

# Check basic internet connectivity
ping -c 3 8.8.8.8

# Check if it's just DNS
curl -v https://registry.terraform.io/.well-known/terraform.json

WORKAROUND:

curl -4 -v https://registry.terraform.io/.well-known/terraform.json

echo 'ipv4' >> ~/.curlrc

sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1

FIX - disable IPv6 permanently:

# Force IPv4 for curl system-wide
echo 'ipv4' >> ~/.curlrc

# Disable IPv6 on network interfaces
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1

# Make it permanent across reboots
echo 'net.ipv6.conf.all.disable_ipv6=1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.default.disable_ipv6=1' | sudo tee -a /etc/sysctl.conf
```

**terraform `init`, `plan` & `apply` - Dev Env**

```
1. terraform init

Terraform has been successfully initialized!

2. terraform plan

Plan: 4 to add, 0 to change, 0 to destroy.
Changes to Outputs:
  + nsg_name                = "nsg-web-azlab-dev"
  + subnet_name             = "snet-web-azlab-dev"
  + vnet_id                 = (known after apply)
  + vnet_name               = "vnet-azlab-dev"

Clean plan! All 4 resources and 4 outputs look exactly right:

+ vnet-azlab-dev        Virtual Network  (10.0.0.0/16)
+ snet-web-azlab-dev    Subnet           (10.0.1.0/24)
+ nsg-web-azlab-dev     NSG              (HTTP/HTTPS allow, all else deny)
+ association           NSG ↔ Subnet

3. terraform apply

Type `yes` when prompted. Once successful we'll commit to the feature branch and raise a PR to main — which will trigger the full GitOps flow:

PR opened
  ├──► Plan (dev)   ← 0 changes (already applied)
  └──► Plan (prod)  ← 4 to add

Merge to main
  └──► Approval gate ──► Apply (prod) ──► prod gets VNet + Subnet + NSG

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:
nsg_name = "nsg-web-azlab-dev"
resource_group_location = "eastus"
resource_group_name = "rg-azlab-dev"
storage_account_name = "stazlabdev001"
storage_blob_endpoint = "https://stazlabdev001.blob.core.windows.net/"
subnet_name = "snet-web-azlab-dev"
vnet_id = "/subscriptions/a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d/resourceGroups/rg-azlab-dev/providers/Microsoft.Network/virtualNetworks/vnet-azlab-dev"
vnet_name = "vnet-azlab-dev"


```

**All 4 resources live on Azure in dev above! Now let's promote to prod via PR — the full GitOps flow:**

Step 1 — Update prod environment files

```
The prod environment needs the same network variables added. Run these commands:

cd ~/terraform-azure-remote-state-lab

# Add network variables to prod variables.tf
cat >> environments/prod/variables.tf << 'EOF'

variable "vnet_address_space" {
  description = "CIDR block for the Virtual Network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_address_prefix" {
  description = "CIDR block for the web subnet"
  type        = string
  default     = "10.0.1.0/24"
}
EOF

# Add network values to prod terraform.tfvars
cat >> environments/prod/terraform.tfvars << 'EOF'

# Network
vnet_address_space    = "10.0.0.0/16"
subnet_address_prefix = "10.0.1.0/24"
EOF

Then update environments/prod/main.tf — add the network module call at the bottom before the closing, same as dev:

cat >> environments/prod/main.tf << 'EOF'

module "network" {
  source                = "../../modules/network"
  project               = var.project
  environment           = var.environment
  location              = var.location
  resource_group_name   = module.resource_group.name
  vnet_address_space    = var.vnet_address_space
  subnet_address_prefix = var.subnet_address_prefix
  tags                  = local.common_tags
}
EOF

And add network outputs to environments/prod/outputs.tf:

cat >> environments/prod/outputs.tf << 'EOF'

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = module.network.vnet_name
}

output "vnet_id" {
  description = "Resource ID of the Virtual Network"
  value       = module.network.vnet_id
}

output "subnet_name" {
  description = "Name of the web subnet"
  value       = module.network.subnet_name
}

output "nsg_name" {
  description = "Name of the Network Security Group"
  value       = module.network.nsg_name
}
EOF

```

Step 2 — Commit and push feature branch

```
git add .
git status
git commit -m "feat: add VNet + Subnet + NSG network module (dev applied)"
git push -u origin feature/add-network
```

Step 3 — Raise a PR

```
gh pr create \
  --title "feat: add VNet + Subnet + NSG network module" \
  --body "Adds reusable network module with VNet, Subnet and NSG. Applied to dev, promoting to prod via GitOps flow." \
  --base main \
  --head feature/add-network

This will trigger terraform-plan.yml — showing 0 changes for dev and 4 to add for prod. 
```

Step 4 — Merge the PR

```
gh pr checks --watch  #watching the CI plan run

✅ Plan (dev)   — No changes
✅ Plan (prod)  — Plan: 4 to add

Once both are green, merge the PR:

gh pr merge --squash --delete-branch
```
This will:

1. Merge `feature/add-network` into `main`
2. Trigger `terraform-apply-prod.yml`
3. Plan (prod) runs first
4. **Pauses for the approval**
5. You approve → Apply (prod) runs → VNet + Subnet + NSG live on Azure prod

Watching for the approval notification — either via email or check:

```
gh run list --workflow=terraform-apply-prod.yml
```

Step 5 — Approval via CLI

```
# List Pending Approvals

gh run list --workflow=terraform-apply-prod.yml


# Then get the specific run ID and check its status (syntax):

gh run view <RUN_ID>


# List pending deployments waiting for approval (syntax)

gh api /repos/techytanveer/terraform-azure-remote-state-lab/actions/runs/<RUN_ID>/pending_deployments


# Approve it (syntax)

gh api \
  --method POST \
  /repos/techytanveer/terraform-azure-remote-state-lab/actions/runs/<RUN_ID>/pending_deployments \
  --field "environment_ids[]=production" \
  --field "state=approved" \
  --field "comment=Approving prod apply via CLI"


# Check the environment ID first

gh api /repos/techytanveer/terraform-azure-remote-state-lab/environments \
  --jq '.environments[] | select(.name=="production") | .id'

~/terraform-azure-remote-state-lab$ gh run list --workflow=terraform-apply-prod.yml
STATUS  TITLE                                                            WORKFLOW                BRANCH  EVENT  ID           ELAPSED  AGE
*       feat: add VNet + Subnet + NSG network module (dev applied) (#1)  Terraform Apply (prod)  main    push   22485969920  4m7s     about 4 minutes ago
✓       Phase2: README                                                   Terraform Apply (prod)  main    push   22476319398  57s      about 5 hours ago
✓       ci: add GitOps flow - terraform apply prod with approval gate    Terraform Apply (prod)  main    push   22475714383  2m0s     about 5 hours ago
~/terraform-azure-remote-state-lab$
~/terraform-azure-remote-state-lab$


# Run ID is 22485969920 


# Get environment ID into variable

ENV_ID=$(gh api /repos/techytanveer/terraform-azure-remote-state-lab/environments \
  --jq '.environments[] | select(.name=="production") | .id')


echo "Environment ID: $ENV_ID"


# APPROVE

gh api \
  --method POST \
  /repos/techytanveer/terraform-azure-remote-state-lab/actions/runs/22485969920/pending_deployments \
  --field "environment_ids[]=$ENV_ID" \
  --field "state=approved" \
  --field "comment=Approving prod apply via CLI"

```

Step 6 — Watch Apply

```
~/terraform-azure-remote-state-lab$ gh run watch 22485969920
✓ main Terraform Apply (prod) · 22485969920
Triggered via push about 5 minutes ago
JOBS
✓ Plan (prod) in 26s (ID 65135567362)
  ✓ Set up job
  ✓ Checkout
  ✓ Setup Terraform
  ✓ Terraform Init
  ✓ Terraform Validate
  ✓ Terraform Plan
  ✓ Upload Plan
  ✓ Post Checkout
  ✓ Complete job
✓ Apply (prod) in 39s (ID 65135619343)
  ✓ Set up job
  ✓ Checkout
  ✓ Setup Terraform
  ✓ Terraform Init
  ✓ Download Plan
  ✓ Terraform Apply
  ✓ Post Checkout
  ✓ Complete job
✓ Run Terraform Apply (prod) (22485969920) completed with 'success'
```
Step 7 — SUMMARY: The full GitOps flow worked out end to end

```
✅ Plan (prod)   — 26s
✅ Apply (prod)  — 39s
✅ Run completed with 'success'

```

Step 8 — Verify the resources are live on Azure

```
az resource list --resource-group rg-azlab-prod --output table


You should see 4 resources now:

stazlabprod001        Microsoft.Storage/storageAccounts
vnet-azlab-prod       Microsoft.Network/virtualNetworks
snet-web-azlab-prod   Microsoft.Network/virtualNetworks/subnets
nsg-web-azlab-prod    Microsoft.Network/networkSecurityGroups
```

**What Just Completed**

```
Feature branch  ──► PR raised
                      │
                      ├──► Plan (dev)   ✅ 0 changes
                      ├──► Plan (prod)  ✅ 4 to add
                      │
                    PR merged to main
                      │
                      ├──► Plan (prod)  ✅ confirmed
                      ├──► Approval gate ✅ approved via CLI
                      └──► Apply (prod) ✅ VNet + Subnet + NSG live
```


---

# Phase 4 -

**What We're Building**

```
modules/
└── vm/
    ├── main.tf        ← Public IP, NIC, RHEL 9 VM
    ├── variables.tf
    └── outputs.tf

modules/network/
└── main.tf            ← Add SSH rule (port 22) to existing NSG
```

**Resource Design**

```
Public IP : pip-azlab-dev (Static)
    │
    └──► NIC : nic-azlab-dev
                    │
                    └──► VM : vm-azlab-dev
                              ├── Size    : Standard_B1s (free tier)
                              ├── OS      : RHEL 9 (latest)
                              ├── Disk    : Standard_LRS 30GB
                              └── Auth    : SSH public key

NSG update:
    ├── Allow HTTPS  (443)  ← existing
    ├── Allow HTTP   (80)   ← existing
    ├── Allow SSH    (22)   ← NEW — your IP only, not 0.0.0.0/0
    └── Deny all inbound    ← existing
```


Step 1 — Security Note on SSH Rule

Rather than allowing SSH from `0.0.0.0/0` (the whole internet — bad practice), we'll restrict it to the current public IP only.

`admin_ip_cidr` and `ssh_public_key` since both are sensitive/machine-specific and shouldn't be hardcoded in files. Add both to `~/.bashrc`.

This is production-grade security.

```
# Check your current public IP
curl -4 ifconfig.me

# Set as environment variable (best for CI/CD)
export TF_VAR_admin_ip_cidr="109.59.219.58/32"

echo 'export TF_VAR_admin_ip_cidr="109.59.219.58/32"' >> ~/.bashrc
source ~/.bashrc

# Generate RSA key pair (4096 bit)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_azure -C "azure-vm-key" -N ""

# Verify it was created
ls ~/.ssh/id_rsa_azure*

Setting SSH key as environment variable, Never hardcode SSH keys in tfvars — use an env var instead:

export TF_VAR_ssh_public_key=$(cat ~/.ssh/id_rsa_azure.pub)

export TF_VAR_admin_ip_cidr="101.59.219.58/32"

echo "Key loaded: ${TF_VAR_ssh_public_key:0:30}..."
```
Step 2 — Create feature branch 

```
cd ~/terraform-azure-remote-state-lab
git checkout main && git pull
git checkout -b feature/add-vm
```
Step 3 — Project structure to modify

```
# New vm module
mkdir -p modules/vm

modules/vm/main.tf
modules/vm/variables.tf
modules/vm/outputs.tf

# Updated network module (adds SSH rule)
modules/network/main.tf
modules/network/variables.tf

# Updated dev environment
environments/dev/main.tf
environments/dev/variables.tf
environments/dev/terraform.tfvars
environments/dev/outputs.tf
```

Step 4 — terraform plan 

```
Plan: 3 to add, 1 to change, 0 to destroy.
Changes to Outputs:
  + private_ip              = (known after apply)
  + public_ip               = (known after apply)
  + ssh_command             = (known after apply)
  + vm_name                 = "vm-azlab-dev"

What's about to happen:

~ nsg-web-azlab-dev     NSG        ← adds SSH rule (port 22, your IP only)
+ pip-azlab-dev         Public IP
+ nic-azlab-dev         NIC
+ vm-azlab-dev          RHEL 9 VM  (Standard_B1s)
```

Step 5 — terraform apply 

```
╷
│ Error: creating Linux Virtual Machine (Subscription: "a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d"
│ Resource Group Name: "rg-azlab-dev"
│ Virtual Machine Name: "vm-azlab-dev"): performing CreateOrUpdate: unexpected status 409 (409 Conflict) with error: SkuNotAvailable: The requested VM size for resource 'Following SKUs have failed for Capacity Restrictions: Standard_B1s' is currently not available in location 'eastus'. Please try another size or deploy to a different location or different zone. See https://aka.ms/azureskunotavailable for details.
│
│   with module.vm.azurerm_linux_virtual_machine.this,
│   on ../../modules/vm/main.tf line 29, in resource "azurerm_linux_virtual_machine" "this":
│   29: resource "azurerm_linux_virtual_machine" "this" {
│
╵
Releasing state lock. This may take a few moments...

```

Step 6 — Change in the plan 

`Standard_B1s` was not available in `eastus` or any other location with free-tier — capacity issue.


The closest offer for my free subscription having $200 credit is 'Standard_D2s_v3 - 2 vcpus, 8 GiB memory ($70.08), in zone 3 of (US) West US 3, Ubuntu pro


Following selected:

```
Size     : Standard_D2s_v3
Region   : westus3
Zone     : 3
OS       : Ubuntu 24.04 LTS (not Pro — Pro costs extra)
```
Updating Config:

```
# Update VM Size

sed -i 's/Standard_B1s/Standard_D2s_v3/' modules/vm/main.tf

# Update location to westus3

sed -i 's/location    = "eastus"/location    = "westus3"/' environments/dev/terraform.tfvars

# Add availability zone to vm module

Now edit modules/vm/main.tf to add zone 3 at two locations:

resource "azurerm_linux_virtual_machine" "this" {
  zone                            = "3"       # ← add this

resource "azurerm_public_ip" "this" {
  zones               = ["3"]       # ← add this

# Verify changes:

grep -E "zone|size|location" modules/vm/main.tf
grep location environments/dev/terraform.tfvars

```
Step 7 — Creating VMs scenarios

| Option | Cost | Complexity | Production-like? |
| ------ | ---- | ---------- | ---------------- |
| Move VM to prod RG | One VM only | Medium | ✅ Yes |
| Import into prod state | One VM only | Low | ✅ Yes |
| Separate instances | Two VMs = double cost | Low | ✅ Most realistic |

Step 8 — Production Scenarios (roadmap)

The Flow

```
Current State:
  rg-azlab-dev  ←  vm-azlab-dev (once created)

Target State:
  rg-azlab-prod ←  vm-azlab-prod (moved from dev)
  rg-azlab-dev  ←  (no VM, dev is for testing only)
```

Steps We'll Follow

```
1. Create VM in dev        (terraform apply in dev)
2. Test VM in dev          (SSH in, verify it works)
3. Move VM to prod RG      (az resource move)
4. Import VM into prod     (terraform import in prod)
5. Remove VM from dev      (terraform state rm in dev)
6. Update prod tfvars      (reflect new VM config)
```

First to verify VM move is supported to move.

Azure resource move has restrictions — not all resources can move between resource groups.

```
# Check if VM resources are moveable
az rest \
  --method post \
  --url "https://management.azure.com/subscriptions/a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d/resourceGroups/rg-azlab-dev/validateMoveResources?api-version=2021-04-01" \
  --body '{
    "resources": [],
    "targetResourceGroup": "/subscriptions/a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d/resourceGroups/rg-azlab-prod"
  }'
```

Step 9 — terraform refresh 

```
Outputs:

nsg_name = "nsg-web-azlab-dev"
private_ip = "10.0.1.4"
public_ip = "20.14.74.45"
resource_group_location = "westus3"
resource_group_name = "rg-azlab-dev"
ssh_command = "ssh -i ~/.ssh/id_rsa_azure azureuser@20.14.74.45"
storage_account_name = "stazlabdev001"
storage_blob_endpoint = "https://stazlabdev001.blob.core.windows.net/"
subnet_name = "snet-web-azlab-dev"
vm_name = "vm-azlab-dev"
vnet_id = "/subscriptions/a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d/resourceGroups/rg-azla
vnet_name = "vnet-azlab-dev"
~/terraform-azure-remote-state-lab/environments/dev$


Previous failed applies     ──► partially created resources on Azure
                                  │
                                  ├── VNet        ✅ created
                                  ├── NSG         ✅ created  
                                  ├── Subnet      ✅ created
                                  ├── Storage     ✅ created
                                  ├── Public IP   ✅ created
                                  ├── NIC         ✅ created
                                  └── VM          ✅ created

terraform refresh             ──► synced state with what was already on Azure
                                  └── all outputs populated from existing resources

```

Step 10 — terraform apply

```

Plan: 5 to add, 0 to change, 1 to destroy.

Changes to Outputs:
  ~ private_ip              = "10.0.1.4" -> (known after apply)
  ~ storage_blob_endpoint   = "https://stazlabdev001.blob.core.windows.net/" -> (know



Apply complete! Resources: 5 added, 0 changed, 1 destroyed.
Outputs:
nsg_name = "nsg-web-azlab-dev"
private_ip = "10.0.1.4"
public_ip = "20.14.74.45"
resource_group_location = "westus3"
resource_group_name = "rg-azlab-dev"
ssh_command = "ssh -i ~/.ssh/id_rsa_azure azureuser@20.14.74.45"
storage_account_name = "stazlabdev001"
storage_blob_endpoint = "https://stazlabdev001.blob.core.windows.net/"
subnet_name = "snet-web-azlab-dev"
vm_name = "vm-azlab-dev"
vnet_id = "/subscriptions/a4093cbf-410e-4ee8-8ba8-9ba7b7a1777d/resourceGroups/rg-azlab-dev/providers/Microsoft.Network/virtualNetworks/vnet-azlab-dev"
vnet_name = "vnet-azlab-dev"
~/terraform-azure-remote-state-lab/environments/dev$
```

Step 11 — Logging into VM

```
ssh -i ~/.ssh/id_rsa_azure azureuser@20.14.74.45

~/terraform-azure-remote-state-lab/environments/dev$ ssh -i ~/.ssh/id_rsa_azure azure
The authenticity of host '20.14.74.45 (20.14.74.45)' can't be established.
ED25519 key fingerprint is SHA256:1DgtlaIHK517GEsW/vTY0ejonCiW0AFQfQcUFYOi8Q4.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '20.14.74.45' (ED25519) to the list of known hosts.
Welcome to Ubuntu 24.04.3 LTS (GNU/Linux 6.14.0-1017-azure x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Sat Feb 28 06:20:58 UTC 2026

  System load:  0.13              Processes:             125
  Usage of /:   5.6% of 28.02GB   Users logged in:       0
  Memory usage: 3%                IPv4 address for eth0: 10.0.1.4
  Swap usage:   0%

Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


The list of available updates is more than a week old.
To check for new updates run: sudo apt update


The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

azureuser@vm-azlab-dev:~$
azureuser@vm-azlab-dev:~$
azureuser@vm-azlab-dev:~$ uname -a
Linux vm-azlab-dev 6.14.0-1017-azure #17~24.04.1-Ubuntu SMP Mon Dec  1 20:10:50 UTC 2
azureuser@vm-azlab-dev:~$ cat /etc/os-release
PRETTY_NAME="Ubuntu 24.04.3 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.3 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=noble
LOGO=ubuntu-logo
azureuser@vm-azlab-dev:~$
```

**The VM is live and accessible! 🎉**

```
✅ OS      : Ubuntu 24.04.3 LTS (Noble Numbat)
✅ Kernel  : 6.14.0-1017-azure
✅ Host    : vm-azlab-dev
✅ SSH     : working with RSA key
✅ Region  : westus3
```

Step 11 — gitOps

```
# From project root

cd ~/terraform-azure-remote-state-lab

# Check what changed

git status
git diff --stat

# Push

git add .
git commit -m "feat: add Linux VM (Ubuntu 24.04, Standard_D2s_v3, westus3) with public IP and RSA SSH"
git push -u origin feature/add-vm

# Raise the PR

gh pr create \
  --title "feat: add Linux VM - Ubuntu 24.04 Standard_D2s_v3 westus3" \
  --body "Adds VM module with Ubuntu 24.04 LTS, Standard_D2s_v3, public IP, RSA SSH auth. NSG updated with SSH rule restricted to admin IP. Applied and verified in dev via SSH." \
  --base main \
  --head feature/add-vm

```

---

# Phase 5 - (in progress)

---

# Phase 6 - (in progress)

---
