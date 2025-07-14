# Setup: Azure DevOps & Secure Infrastructure Bootstrap

This directory contains Terraform code and scripts to bootstrap all required Azure DevOps and Azure resources for the ServiceNow Azure AD SSO Automation project.

For overall architecture, design decisions, and security rationale, see the [root README](../README.md).

## What This Sets Up
- Azure DevOps Project, Repos, Pipelines, Service Connections
- Azure Key Vault for secrets (referenced by pipelines)
- Azure Storage Account for Terraform state (CMK-encrypted)
- Private networking for all resources
- Self-hosted Azure DevOps agent pool (VMSS-based)

> **Note:** Terraform modules are now managed in a separate repository (e.g., `terraform-azure-modules`).

## Setup Instructions

### 1. Prepare Your Setup Variables
- Copy the example below into a file named `setup.auto.tfvars` (or any `.tfvars` file):

```hcl
azdo_org_service_url      = "https://dev.azure.com/yourorg"
azdo_project_name         = "your-project"
resource_group_name       = "your-rg"
location                  = "eastus"
key_vault_name            = "your-keyvault"
storage_account_name      = "yourtfstateacct"
vnet_name                 = "your-vnet"
vnet_address_space        = "10.0.0.0/16"
subnet_address_prefix     = "10.0.1.0/24"
agent_vmss_name           = "your-agent-vmss"
agent_admin_username      = "azureuser"
agent_admin_password      = "<secure-password>"
agent_pool_name           = "your-agent-pool"
tenant_id                 = "<your-tenant-id>"
subscription_id           = "<your-subscription-id>"
client_id                 = "<your-client-id>"
client_secret             = "<your-client-secret>"
vending_machine_repo_name = "azure-vending-machine"
modules_repo_name         = "terraform-azure-modules"
```

- **Never commit your secrets to version control.**
- The Azure DevOps PAT is **not** set in this file. It is handled securely as described below.

### 2. Generate and Store the Azure DevOps PAT
- In Azure DevOps, go to User Settings > Personal Access Tokens and create a new PAT scoped to your organization, but limited to the specific project where automation will run. Grant only the following permissions:
  - **Project & Team (Read/Write)** (for the project)
  - **Service Connections (Read/Write)** (for the project)
  - **Variable Groups (Read/Write)** (for the project)
  - **Agent Pools (Read/Write)** (for the project)
  - **Code (Read/Write)** (for the project, but restrict to only the repos that require write access; set to Read for repos that only need to be read)

  When configuring the PAT, select the project scope and, for the Code scope, specify Read/Write for the automated-deployment repo and Read for the modules repo. This ensures least-privilege access.
- **Do not put the PAT in any tfvars file or commit it to version control.**

#### Bootstrap the Key Vault for PAT Storage
1. Deploy the core infrastructure (resource group, Key Vault, VNet, subnet, etc.) so Key Vault is available:
   ```sh
   terraform apply -target=azurerm_resource_group.main -target=azurerm_key_vault.main -target=azurerm_virtual_network.main -target=azurerm_subnet.private
   ```
2. Store the PAT in Key Vault as the secret `azdo-pat`:
   ```sh
   az keyvault secret set --vault-name <key_vault_name> --name azdo-pat --value <your_pat>
   ```

### 3. Complete the Deployment
- Run `terraform apply` again (with your normal variable file) to complete the deployment. All DevOps resources and automation will now use the PAT securely from Key Vault.
- For future PAT rotation, update the Key Vault secret and re-run Terraform or trigger the provided rotation pipeline/script as needed. See `scripts/rotate-azdo-pat.sh` and `azure-pipelines-rotate-pat.yml` for automated rotation.

### 4. (Optional) Use the Bootstrap Script
- You can use the provided script to automate the above steps:

```bash
cd setup
AZDO_PERSONAL_ACCESS_TOKEN="<your-pat-here>" ./bootstrap_setup.sh -var-file=setup.auto.tfvars
```

## ITSM Integration: Sending Requests

This solution abstracts ITSM integration (e.g., ServiceNow) for flexibility. To configure your ITSM tool to send requests:
- Review the ITSM integration abstraction in the `/src/servicenow/` directory.
- Update or replace the integration script or pipeline step to match your ITSM system's API and authentication.
- Example request payloads and scripts are provided in the `scripts/` directory.
- For more details, see the main project README and comments in the ITSM integration code.

## Next Steps
- Review Terraform outputs for resource details and next steps (e.g., agent registration, manual approvals).
- Configure your Azure DevOps pipelines to use the created resources and reference the modules repo as described in the main README.

## Files
- `main.tf`         – Main Terraform configuration
- `variables.tf`    – Input variables
- `outputs.tf`      – Outputs for integration
- `bootstrap_setup.sh` – Script to run the setup

---
**Note:**
- You must have sufficient Azure and Azure DevOps permissions to run this setup.
- Review and update variables as needed for your environment.
- Follow security best practices for all credentials and secrets.

# Changes
- The bootstrap process now automatically grants the current user running Terraform the Key Vault Administrator role on the Key Vault, ensuring you have the necessary permissions for secret management during initial deployment. This prevents 403 errors and allows the deployment to proceed smoothly.
- All variables and automation are now aligned for managed identity and auto-generated password best practices.
