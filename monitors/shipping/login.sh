#!/bin/bash

TOKEN_FILE=".api_token"
API_URL="https://onetracker.app/api/auth/token"

read -p "Email: " email
read -s -p "Password: " password
echo

response=$(curl -s -X POST "$API_URL" \
  -d "{\"email\": \"$email\", \"password\": \"$password\"}")

rpc_status=$(echo "$response" | jq -r '.message')
if [[ "$rpc_status" != "ok" ]]; then
  echo "Failed to get API token: $response"
  exit 1
else
  echo "Login successfully. Writing token to $TOKEN_FILE ..."
fi

token=$(echo "$response" | jq -r '.session.token')
expiration=$(echo "$response" | jq -r '.session.expiration')

cat <<EOF > $TOKEN_FILE
token=$token
expiration=$expiration
EOF

