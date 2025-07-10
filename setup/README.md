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

### 1. Generate a Personal Access Token (PAT) for Azure DevOps
- Go to Azure DevOps > User Settings > Personal Access Tokens.
- Click "New Token".
- Set the following:
  - **Organization**: Your Azure DevOps org
  - **Scopes**: Project & Team (Read/Write), Code (Read/Write), Service Connections (Read/Write), Variable Groups (Read/Write), Agent Pools (Read/Write)
  - **Expiration**: As appropriate for your security policy
- Copy the PAT and store it securely. **Do not put the PAT in your tfvars file or commit it to version control.**

### 2. Prepare Your Setup Variables
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
- The PAT should be provided as an environment variable at runtime.

### 3. Set the PAT as an Environment Variable

Before running Terraform, set your PAT in your shell:

```bash
export AZDO_PERSONAL_ACCESS_TOKEN="<your-pat-here>"
```

Or, if you use a different shell or CI/CD system, set the environment variable accordingly.

### 4. Run the Bootstrap Script

```bash
cd setup
terraform init
terraform apply -var-file=setup.auto.tfvars
```

Or, if using the provided script:

```bash
cd setup
AZDO_PERSONAL_ACCESS_TOKEN="<your-pat-here>" ./bootstrap_setup.sh -var-file=setup.auto.tfvars
```

### 5. Next Steps
- Review the outputs for resource details and next steps (e.g., agent registration, manual approvals).
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
