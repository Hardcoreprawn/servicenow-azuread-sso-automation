#!/bin/bash
# list_requests.sh
# Lists all current app SSO requests and their metadata.
# Usage: ./scripts/list_requests.sh

find requests -type f -name 'main.tf' | while read tf; do
  echo "---"
  echo "Request: $tf"
  grep '^#   ' "$tf" | sed 's/^#   //'
  echo "---"
done
