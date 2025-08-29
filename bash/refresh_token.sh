#!/bin/bash

# Fetch new token
response=$(curl -s --fail --show-error \
  https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token \
  -d grant_type=refresh_token \
  -d client_id="cloud-services" \
  -d refresh_token="eyJhbGciOiJIUzUxMiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI0NzQzYTkzMC03YmJiLTRkZGQtOTgzMS00ODcxNGRlZDc0YjUifQ")

# Extract access token
access_token=$(echo "$response" | jq -r '.access_token')

# Validate token
if [[ -z "$access_token" || "$access_token" == "null" ]]; then
  echo "Failed to retrieve access token"
  exit 1
fi

# Update ansible.cfg
cfg_path="$HOME/Downloads/GIT/ansible.cfg"
if [[ -f "$cfg_path" ]]; then
  sed -i.bak -E "s|^token *=.*|token = $access_token|" "$cfg_path"
  echo "ansible.cfg updated with new token"
else
  echo "ansible.cfg not found at $cfg_path"
  exit 2
fi

