#!/bin/bash
# update_request.sh
# Update variables or metadata in an existing app SSO request.
# Usage: ./scripts/update_request.sh <app_name> <ticket> <action> <variable> <new_value>
# Example: ./scripts/update_request.sh hr-onboarding-app SNOW12345 create app_name new-app-name

set -e

APP=$1
TICKET=$2
ACTION=$3
VAR=$4
VAL=$5
TFVARS="requests/$APP/${TICKET}-${ACTION}/variables.tf"

if [ -z "$APP" ] || [ -z "$TICKET" ] || [ -z "$ACTION" ] || [ -z "$VAR" ] || [ -z "$VAL" ]; then
  echo "Usage: $0 <app_name> <ticket> <action> <variable> <new_value>"
  exit 1
fi

if [ ! -f "$TFVARS" ]; then
  echo "Error: $TFVARS not found."
  exit 2
fi

sed -i "s|^variable \"$VAR\".*|variable \"$VAR\" { default = \"$VAL\" }|" "$TFVARS"
echo "Updated $VAR in $TFVARS to $VAL."
