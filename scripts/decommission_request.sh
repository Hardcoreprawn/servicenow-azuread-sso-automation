#!/bin/bash
# decommission_request.sh
# Mark a request as decommissioned and optionally destroy its resources.
# Usage: ./scripts/decommission_request.sh <app_name> <ticket> <action>

set -e

APP=$1
TICKET=$2
ACTION=$3
REQ_DIR="requests/$APP/${TICKET}-${ACTION}"

if [ -z "$APP" ] || [ -z "$TICKET" ] || [ -z "$ACTION" ]; then
  echo "Usage: $0 <app_name> <ticket> <action>"
  exit 1
fi

if [ ! -d "$REQ_DIR" ]; then
  echo "Error: $REQ_DIR not found."
  exit 2
fi

# Mark as decommissioned
for tf in "$REQ_DIR"/*.tf; do
  if ! grep -q '^# DECOMMISSIONED:' "$tf"; then
    echo "# DECOMMISSIONED: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$tf"
  fi
  echo "Marked $tf as decommissioned."
done

echo "To destroy resources, run: (cd $REQ_DIR && terraform destroy)"
# Optionally, move to archive/ or remove after destroy
