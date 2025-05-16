#!/bin/bash

TOKEN_FILE=".api_token"
API_URL="https://onetracker.app/api/parcels?archived=false"

if [ ! -f "$TOKEN_FILE" ]; then
  echo '{"text": "Token not found", "imagesymbol": "exclamationmark.triangle"}'
  exit 1
fi

source "$TOKEN_FILE"

expiration_epoch=$(date -jf "%Y-%m-%dT%H:%M:%S" "${expiration:0:19}" +%s 2>/dev/null)
now_epoch=$(date +%s)

if (( now_epoch >= expiration_epoch )); then
  echo '{"text": "Token has expired", "imagesymbol": "exclamationmark.triangle"}'
  exit 1
fi

response=$(curl -s "$API_URL" -H "Cookie: api_token=$token")
rpc_status=$(echo "$response" | jq -r '.message')

if [[ "$rpc_status" != "ok" ]]; then
  echo '{"text": "API failed", "imagesymbol": "exclamationmark.triangle"}'
  exit 1
fi

menu_items=$(echo "$response" | jq -r '
    [.parcels[] | {
      text: "\(.description): \(.tracking_status_readable)",
      click: "/usr/bin/open https://www.google.com/search?q=\(.carrier)+\(.tracking_id)"
    }] | tojson')
echo '
{
  "imagesymbol": "shippingbox.fill",
  "text": "",
  "menus": '$menu_items'
}'
