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

## Usage
1. Set required environment variables (see `variables.tf` for details).
2. Run `./bootstrap_setup.sh` to initialize and apply the infrastructure.
3. When configuring pipelines, add the modules repo as a pipeline resource using `resources.repositories`.
4. Reference modules in your Terraform code using the relative path to the checked-out modules directory (see root README for examples).

## Files
- `main.tf`         – Main Terraform configuration
- `variables.tf`    – Input variables
- `outputs.tf`      – Outputs for integration
- `bootstrap_setup.sh` – Script to run the setup

---
**Note:**
- You must have sufficient Azure and Azure DevOps permissions to run this setup.
- Review and update variables as needed for your environment.
