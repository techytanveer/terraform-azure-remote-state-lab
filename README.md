# terraform-azure-remote-state-lab

A hands-on Terraform lab using **Azure Blob Storage as a remote state backend**
— going beyond local state with a production-grade modular project structure.

## What This Lab Covers

- Azure provider setup and Service Principal authentication
- Remote state backend using **Azure Blob Storage** with state locking
- Modular Terraform structure with reusable `modules/`
- Separate isolated `dev` and `prod` environments
- GitHub Actions CI pipeline running `terraform plan` on every PR

## Project Structure

```
terraform-azure-remote-state-lab/
├── .gitignore
├── .github/
│   └── workflows/
│       └── terraform-plan.yml        # CI: terraform plan on every PR
├── scripts/
│   └── bootstrap.sh                  # One-time: creates blob backend on Azure
├── modules/
│   ├── resource-group/
│   │   ├── main.tf                   # Creates azurerm_resource_group
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── storage/
│       ├── main.tf                   # Creates azurerm_storage_account
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    ├── dev/
    │   ├── backend.tf                # Remote state: dev/terraform.tfstate
    │   ├── main.tf                   # Provider + module wiring
    │   ├── variables.tf
    │   ├── terraform.tfvars          # Dev values
    │   └── outputs.tf
    └── prod/
        ├── backend.tf                # Remote state: prod/terraform.tfstate
        ├── main.tf
        ├── variables.tf
        ├── terraform.tfvars          # Prod values
        └── outputs.tf
```

## Prerequisites

- Ubuntu 24.04 LTS
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Terraform >= 1.6](https://developer.hashicorp.com/terraform/install)
- Azure account (free tier with $200 credit works)
- Service Principal with Contributor role

## Quick Start

### 1. Bootstrap the Remote State Backend (run once)

```bash
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh
```

Copy the storage account name from the output, then update **both**:
- `environments/dev/backend.tf`
- `environments/prod/backend.tf`

Replace `REPLACE_WITH_STORAGE_ACCOUNT` with your actual storage account name.

### 2. Export Azure credentials

```bash
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
export ARM_CLIENT_ID="your-app-id"
export ARM_CLIENT_SECRET="your-password"
```

### 3. Deploy dev environment

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

### 4. Destroy when done (saves your Azure credits)

```bash
terraform destroy
```

## Why Remote State?

| Feature              | Local State | Azure Blob Backend |
|----------------------|-------------|-------------------|
| Safe if laptop dies  | ❌          | ✅                |
| Team collaboration   | ❌          | ✅                |
| State locking        | ❌          | ✅                |
| State versioning     | ❌          | ✅                |
| Cost                 | Free        | ~$0.01/month      |

## GitHub Actions Setup

Add these secrets under `Settings → Secrets → Actions`:

| Secret | Value |
|--------|-------|
| `ARM_SUBSCRIPTION_ID` | Your Azure subscription ID |
| `ARM_TENANT_ID` | From service principal output |
| `ARM_CLIENT_ID` | `appId` from service principal |
| `ARM_CLIENT_SECRET` | `password` from service principal |

## Author

Built on Ubuntu 24.04 LTS · Azure Free Tier ($200 credit)
