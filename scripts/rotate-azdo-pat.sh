#!/usr/bin/env bash
# rotate-azdo-pat.sh
# Rotates an Azure DevOps PAT and updates Azure Key Vault if the PAT is older than 75% of its lifetime
# Requirements: az CLI, curl, jq

set -euo pipefail

# --- CONFIG ---
ORG_URL="$1"           # e.g. https://dev.azure.com/yourorg
USERNAME="$2"         # Azure DevOps user (email)
AZDO_TOKEN="$3"       # Existing PAT with 'Token Administration' scope
KEYVAULT_NAME="$4"    # Azure Key Vault name
SECRET_NAME="azdo-pat" # Key Vault secret name
PAT_NAME="Terraform Automation"
PAT_SCOPES="vso.code vso.project vso.build vso.variablegroup vso.agentpools vso.serviceendpoint"
PAT_DURATION=30        # Days
ROTATE_THRESHOLD=0.75  # Rotate if 75% of lifetime elapsed

# --- CHECK PAT AGE ---
SECRET_JSON=$(az keyvault secret show --vault-name "$KEYVAULT_NAME" --name "$SECRET_NAME" --query "{value:value,updated:attributes.updated,expires:attributes.expires}" -o json)
PAT_UPDATED=$(echo "$SECRET_JSON" | jq -r '.updated')
PAT_EXPIRES=$(echo "$SECRET_JSON" | jq -r '.expires')

if [[ "$PAT_EXPIRES" == "null" || -z "$PAT_EXPIRES" ]]; then
  echo "PAT in Key Vault does not have an expiry. Rotating now."
  ROTATE=1
else
  UPDATED_TS=$(date -d "$PAT_UPDATED" +%s)
  EXPIRES_TS=$(date -d "$PAT_EXPIRES" +%s)
  NOW_TS=$(date +%s)
  LIFETIME=$((EXPIRES_TS - UPDATED_TS))
  AGE=$((NOW_TS - UPDATED_TS))
  THRESHOLD=$(echo "$LIFETIME * $ROTATE_THRESHOLD" | bc | awk '{print int($1+0.5)}')
  if (( AGE >= THRESHOLD )); then
    echo "PAT is older than 75% of its lifetime. Rotating."
    ROTATE=1
  else
    echo "PAT is still valid and not old enough to rotate."
    ROTATE=0
  fi
fi

if (( ROTATE == 0 )); then
  exit 0
fi

# --- CREATE NEW PAT ---
NEW_PAT=$(curl -s -u "$USERNAME:$AZDO_TOKEN" \
  -X POST "$ORG_URL/_apis/tokens/pats?api-version=7.1-preview.1" \
  -H "Content-Type: application/json" \
  -d "{\"displayName\":\"$PAT_NAME\",\"scope\":\"$PAT_SCOPES\",\"validTo\":\"$(date -u -d "+$PAT_DURATION days" +%Y-%m-%dT%H:%M:%SZ)\",\"allOrgs\":false}" \
  | jq -r '.patToken')

if [[ -z "$NEW_PAT" || "$NEW_PAT" == "null" ]]; then
  echo "Failed to create new PAT."
  exit 1
fi

echo "New PAT created. Updating Key Vault..."

# --- UPDATE KEY VAULT ---
az keyvault secret set --vault-name "$KEYVAULT_NAME" --name "$SECRET_NAME" --value "$NEW_PAT" --expires "$(date -u -d "+$PAT_DURATION days" +%Y-%m-%dT%H:%M:%SZ)"

echo "PAT rotated and stored in Key Vault as $SECRET_NAME."
