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

---

Future requests and actions will be appended here chronologically.
