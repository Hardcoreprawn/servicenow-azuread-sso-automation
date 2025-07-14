# User Request Log

This file records all user requests and actions taken by GitHub Copilot for persistent context and traceability.

---

**2025-07-09**
- User requested to tidy up the project, resolve deprecated and vulnerable npm packages using `npm audit fix` and related commands. All vulnerabilities and outdated dependencies were resolved.
- User requested to keep documentation up to date and maintain a persistent log of user requests and actions.
- User clarified that the ServiceNow workflow cannot be changed, but automated actions can be triggered from it.
- The automated action will create an App SSO resource in the Azure DevOps repo, named for the service being added.
- The repo should be structured for automated IaC requests by:
  - Originating department
  - Application the request is for
  - Service request (where Terraform/Bicep/other artifacts are created)
- Each request type will be built from an IaC module or template, with different types having different nuances.
- For now, focus on Terraform: a simple request creates an AppID in Entra by collecting/generating needed info, adding app resources in Terraform, creating a group for access, and storing everything back in DevOps.
- Implemented a Terraform module (`terraform/modules/app_sso`) to provision an Azure AD AppID, an owner group, and a users group.
- The module accepts parameters for app name, requester object ID, and a list of user/group object IDs. It automates naming and group assignments as described.
- Added the official Terraform devcontainer feature to `.devcontainer/devcontainer.json` to ensure Terraform is always available in the development environment.
- Upgraded the devcontainer to use the latest version of Terraform by specifying the latest version in the Terraform feature configuration.
- User considered switching to Alpine for a smaller container, but decided to continue with Ubuntu for compatibility and feature support reasons.
- Updated the Dockerfile to install Terraform from the official HashiCorp apt repository, ensuring the latest version is always installed.
- Added a sample Azure DevOps pipeline (`azure-pipelines.yml`) that runs Terraform and updates ServiceNow tickets.
- Created a template directory (`templates/app_sso/`) with example `main.tf` and `variables.tf` for new app requests.
- Added a script (`scripts/new_app_request.sh`) to automate creation of new app request directories.
- Created a `requests/` directory for new IaC service requests.
- Cleaned up the workspace by removing all Node.js, ServiceNow, and Azure DevOps JS files, configs, and dependencies.
- Removed `postCreateCommand` and `forwardPorts` from devcontainer config as Node.js is no longer needed.
- Created three example/test requests in the `requests/` folder for HR/Onboarding, IT/Support, and Finance/Payroll, each with a unique ServiceNow ticket ID and sample data.
- Added a two-pipeline workflow: one pipeline to create new requests in the repo, and a second pipeline to process requests and update ServiceNow.
- Updated the main pipeline to only trigger on changes in `requests/`, and to run Terraform for each new/changed request.
- Updated the README to reflect the new, simplified, IaC- and pipeline-driven workflow.
- Added scripts for full CRUD lifecycle management of requests:
  - `scripts/list_requests.sh` to list all requests and their metadata.
  - `scripts/update_request.sh` to update variables or metadata in a request.
  - `scripts/decommission_request.sh` to mark a request as decommissioned and guide safe resource destruction.
- Updated all request management scripts to use the new structure: requests/<app_name>/<ticket>-<action>/
- Documented the new structure for clarity and maintainability.
- User requested automation of Azure DevOps and secure infrastructure setup using Terraform, with all resources private, state encrypted with CMK, secrets in Key Vault, and self-hosted agents.
- Created `/setup` directory with:
  - `main.tf`, `variables.tf`, `outputs.tf`: Well-documented Terraform for Azure DevOps project, pipeline, service connection, Key Vault-backed variable group, Key Vault, Storage Account (CMK), VNet, subnet, and VMSS-based self-hosted agent pool.
  - `bootstrap_setup.sh`: Script to initialize and apply the setup.
  - `README.md`: Documentation for setup, security, and usage.
- Validated and corrected Terraform code for provider compatibility and security best practices.
- All secrets are to be stored in Key Vault and exposed to pipelines via variable group. All resources are private, and state is encrypted with a customer-managed key.
- Updated bootstrap setup to provision both the vending machine and modules Azure DevOps repos.
- Updated documentation and pipeline examples to use Azure DevOps pipeline resources for referencing the modules repo, supporting a split multi-repo workflow.
- Removed local modules directory; all modules are now managed in a separate repo and referenced via pipeline resources.
- Switched Azure DevOps service connection from Service Principal to User Assigned Managed Identity (UAMI) using Workload Identity Federation for improved security and modern Azure best practices.
- Added private endpoints for both Key Vault and Storage Account, using the private subnet.
- Reordered resources so that networking (VNet & Subnet) is created before resources that depend on it (Key Vault, Storage Account, and their private endpoints).
- Updated resource numbering and comments for clarity.
- All changes are dependency-aware and maintain implicit ordering.
- Added a bootstrap Key Vault Administrator role assignment for the current user running Terraform, ensuring initial management permissions and preventing 403 errors during deployment. **Note:** The Key Vault Administrator role does not grant access to read or manage secrets; for secret access, assign the Key Vault Secrets User or Key Vault Secrets Officer role as appropriate.
- Cleaned up variables and configuration to match managed identity and auto-generated password best practices.

---

**2025-07-10**
- Updated VMSS agent pool image to use Ubuntu 22.04 LTS (`0001-com-ubuntu-server-jammy`, `22_04-lts`) for maximum compatibility and stability. Noted that Ubuntu 24.04 LTS is not yet available in Azure Marketplace for VMSS as of this date.

---

**2025-07-11**
- User requested to implement a dedicated user-assigned managed identity for the storage account to access the CMK in Key Vault, and to assign the required Key Vault role.
- Design decision: Created `azurerm_user_assigned_identity.storage_cmk` for the storage account, assigned it the `Key Vault Crypto Officer` role, and updated the storage account to use this UAMI for CMK.
- Noted that key rotation is not automated in this implementation, but the UAMI is ready for future automation.

---

- Refactored Terraform codebase for clarity and maintainability:
  - Moved provider and terraform blocks to `providers.tf`.
  - Moved data sources to `data.tf`.
  - Split resources into logical files: `infra_network.tf`, `infra_keyvault.tf`, `infra_storage.tf`, `infra_vmss.tf`, `infra_identities.tf`, `infra_role_assignments.tf`, `infra_bootstrap_roles.tf`, `infra_azdo.tf`.
  - Updated documentation with new file structure and organization principles.
- All resources are now grouped with their enablers, children, and role assignments for easier navigation and maintenance.

---

- User requested to update the persistent log in the background after recent changes to the Terraform infrastructure code.
- No new infrastructure changes were made in this request; this is a meta/logging update only.
- All previous changes (dynamic client IP allow-listing, provider block cleanup, variable removal, role assignments, etc.) are up to date as of this entry.

---

**2025-07-14**
- Added automation to set `AZDO_PERSONAL_ACCESS_TOKEN` from Azure Key Vault on devcontainer start.
- Script now extracts `key_vault_name` from `setup.auto.tfvars` or environment variable for flexibility.
- Updated `.devcontainer/devcontainer.json` to run this script automatically.
- Design decision: Always prefer tfvars for vault name, fallback to env, and fail with clear error if not set.

---

Future requests and actions will be appended here chronologically.
