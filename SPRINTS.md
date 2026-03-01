# Sprint Tracker — terraform-azure-remote-state-lab

## Sprint 1 ✅ Foundation
| Story | Branch | PR | Status |
|---|---|---|---|
| Remote state backend | - | - | ✅ Done |
| Modular structure | - | - | ✅ Done |
| CI pipeline | - | - | ✅ Done |

## Sprint 2 ✅ GitOps Flow
| Story | Branch | PR | Status |
|---|---|---|---|
| Terraform apply prod | - | - | ✅ Done |
| Human approval gate | - | - | ✅ Done |
| workflow_dispatch trigger | - | - | ✅ Done |

## Sprint 3 ✅ Infrastructure
| Story | Branch | PR | Status |
|---|---|---|---|
| VNet + Subnet + NSG | feature/add-network | #1 | ✅ Done |
| Linux VM (Ubuntu 24.04) | feature/add-vm | #2 | ✅ Done |

## Sprint 4 🔄 Secrets Management
| Story | Branch | PR | Status |
|---|---|---|---|
| Key Vault module | feature/add-keyvault | - | 🔲 Todo |
| Store SSH key in vault | feature/add-keyvault | - | 🔲 Todo |
| VM reads key from vault | feature/add-keyvault | - | 🔲 Todo |

## Sprint 5 📋 VM Promotion
| Story | Branch | PR | Status |
|---|---|---|---|
| Move VM dev → prod RG | feature/vm-promotion | - | 🔲 Todo |
| Import into prod state | feature/vm-promotion | - | 🔲 Todo |
| Verify prod SSH access | feature/vm-promotion | - | 🔲 Todo |

## Sprint 6 📋 Observability
| Story | Branch | PR | Status |
|---|---|---|---|
| Auto-shutdown schedule | feature/auto-shutdown | - | 🔲 Todo |
| Azure Monitor alerts | feature/monitoring | - | 🔲 Todo |
| Backup policy | feature/backup | - | 🔲 Todo |

## Agile Metrics
| Metric | Value |
|---|---|
| Sprints completed | 3 |
| PRs merged | 2 |
| Resources deployed (dev) | 8 |
| Resources deployed (prod) | 6 |
| State locks broken | 3 |
| Regions tried | 3 (eastus, eastus2, westus3) |
