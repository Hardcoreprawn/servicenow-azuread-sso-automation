#!/bin/bash
# new_app_request.sh
# Script to create a new app SSO request directory from a template.
# Usage: ./scripts/new_app_request.sh <app_name> <ticket> <action>
#
# Arguments:
#   <app_name>   - The unique name of the application (e.g., hr-onboarding-app)
#   <ticket>     - The ServiceNow ticket number (e.g., SNOW12345)
#   <action>     - The type of request (e.g., create, update, decommission)
#
# This script ensures:
#   - Consistent directory structure for all requests
#   - Easy onboarding for new maintainers
#   - Safety: will not overwrite existing requests

set -e

APP=$1
TICKET=$2
ACTION=$3
DEST="requests/$APP/${TICKET}-${ACTION}"
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ -z "$APP" ] || [ -z "$TICKET" ] || [ -z "$ACTION" ]; then
  echo "Usage: $0 <app_name> <ticket> <action>"
  exit 1
fi

if [ -d "$DEST" ]; then
  echo "Error: Request directory $DEST already exists. Aborting to prevent overwrite."
  exit 2
fi

mkdir -p "$DEST"
for f in templates/app_sso/*; do
  fname=$(basename "$f")
  cat <<EOF > "$DEST/$fname"
# ---
# Request Metadata
#   App Name: $APP
#   Ticket Reference: $TICKET
#   Action: $ACTION
#   Created: $NOW
#   Completed: <to-be-filled-by-pipeline>
# ---
$(cat "$f")
EOF
  done

echo "Created new app SSO request at $DEST with metadata comments."
