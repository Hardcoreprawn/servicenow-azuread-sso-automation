#!/bin/bash
set -euo pipefail

# Bootstrap script for Azure DevOps and secure infra setup
# Usage: ./bootstrap_setup.sh

cd "$(dirname "$0")"

# Export required environment variables before running (see variables.tf)
# export AZDO_ORG_SERVICE_URL=...
#
# On the first run, you must provide the Azure DevOps PAT as an environment variable:
# export TF_VAR_azdo_pat=...   # (PAT will be written to Key Vault)
#
# On subsequent runs, you do NOT need to set TF_VAR_azdo_pat; it will be read from Key Vault.
#
# All Azure resource permissions for the Managed Identity used by the Service Connection
# are assigned automatically by Terraform (see main.tf). No ARM_* variables are needed.

terraform init
terraform apply -auto-approve

echo -e "\n[INFO] Setup complete. Review outputs above for next steps."
