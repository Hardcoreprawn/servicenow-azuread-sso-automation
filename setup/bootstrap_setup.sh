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
# export AZDO_PERSONAL_ACCESS_TOKEN=...
# export AZDO_ORG_SERVICE_URL=...

terraform init
terraform apply -auto-approve

echo "\n[INFO] Setup complete. Review outputs above for next steps."
