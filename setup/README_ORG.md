# Terraform Organization and File Structure

## File Layout

- `providers.tf` — Terraform and provider blocks
- `data.tf` — Data sources
- `infra_network.tf` — Resource group, VNet, subnet
- `infra_keyvault.tf` — Key Vault, key, private endpoint, and all related role assignments
- `infra_storage.tf` — Storage account, UAMI, private endpoint, and related role assignments
- `infra_vmss.tf` — VMSS, admin password, and UAMI for DevOps
- `infra_identities.tf` — Managed identities for DevOps and role assignments
- `infra_role_assignments.tf` — Additional role assignments for storage and Key Vault
- `infra_bootstrap_roles.tf` — Bootstrap role assignments for Key Vault
- `infra_azdo.tf` — Azure DevOps project, agent pool, service connection, variable group, repos, pipelines, and Key Vault secrets
- `outputs.tf` — Outputs
- `variables.tf` — Variables

## Organization Principles

- Each major Azure or DevOps resource is grouped with its enablers, children, and role assignments.
- Providers and data sources are separated for clarity and maintainability.
- Outputs and variables are kept in their own files.

## How to Add New Resources

- Place new resources in the most relevant file, or create a new file if a new logical group is needed.
- Keep related role assignments and dependencies close to the resource they enable.

## Getting Started

1. Edit variables in `variables.tf` as needed.
2. Run `terraform init` and `terraform apply` in the `setup` directory.
3. Review outputs in `outputs.tf` for integration points.

---

## Devcontainer PAT Automation

The devcontainer automatically loads the Azure DevOps PAT from Azure Key Vault at startup for all local development sessions. If you change the Key Vault secret name or the tfvars file, update `setup/set_azdo_pat_env.sh` accordingly.
