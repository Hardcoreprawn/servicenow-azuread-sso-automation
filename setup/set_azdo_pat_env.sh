#!/bin/bash
# Set AZDO_PERSONAL_ACCESS_TOKEN from Azure Key Vault on devcontainer start

# Try to extract key_vault_name from setup.auto.tfvars (or fallback to env var)
TFVARS_FILE="${TFVARS_FILE:-setup.auto.tfvars}"

# Extract key_vault_name from tfvars (assumes simple assignment, no interpolation)
if [ -f "$TFVARS_FILE" ]; then
  KEY_VAULT_NAME=$(grep -E '^\s*key_vault_name\s*=\s*"' "$TFVARS_FILE" | sed -E 's/.*=\s*"([^"]+)".*/\1/')
fi

# Allow override from environment
KEY_VAULT_NAME="${KEY_VAULT_NAME:-${KEY_VAULT_NAME_ENV:-your-keyvault}}"

if [ -z "$KEY_VAULT_NAME" ] || [ "$KEY_VAULT_NAME" = "your-keyvault" ]; then
  echo "ERROR: key_vault_name not set. Please set in $TFVARS_FILE or export KEY_VAULT_NAME_ENV."
  return 1 2>/dev/null || exit 1
fi

export AZDO_PERSONAL_ACCESS_TOKEN="$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name azdo-pat --query value -o tsv)"
