#!/bin/bash
set -euo pipefail

# Bootstrap script for Azure DevOps and secure infra setup
# Usage: ./bootstrap_setup.sh

cd "$(dirname "$0")"

# Export required environment variables before running (see variables.tf)
# export ARM_CLIENT_ID=...
# export ARM_CLIENT_SECRET=...
# export ARM_SUBSCRIPTION_ID=...
# export ARM_TENANT_ID=...
# export AZDO_ORG_SERVICE_URL=...
#
# On the first run, you must provide the Azure DevOps PAT as an environment variable:
# export TF_VAR_azdo_pat=...   # (PAT will be written to Key Vault)
#
# On subsequent runs, you do NOT need to set TF_VAR_azdo_pat; it will be read from Key Vault.

terraform init
terraform apply -auto-approve

echo -e "\n[INFO] Setup complete. Review outputs above for next steps."
