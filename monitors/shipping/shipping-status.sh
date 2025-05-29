#!/usr/bin/env bash

TOKEN_FILE="$(dirname $0)/.api_token"
SNAPSHOT_FILE="$(dirname $0)/.snapshot"
API_URL="https://onetracker.app/api/parcels?archived=false"
ARCHIVE_SH="$(dirname $0)/archive.sh"

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

if [[ -f "$SNAPSHOT_FILE" ]]; then
  prev_snapshot=$(<"$SNAPSHOT_FILE")
fi
new_snapshot=$(echo "$response" | jq -r '
[.parcels[] | {
  id: "\(.id)",
  status: "\(.tracking_status)",
  location: "\(.tracking_location)"
}] | tojson')
echo "$new_snapshot" > "$SNAPSHOT_FILE.tmp"

if [[ "$new_snapshot" != "$prev_snapshot" ]]; then
  # Show a filled icon when there is update
  symbol="shippingbox.fill"
else
  symbol="shippingbox"
fi

menu_items=$(echo "$response" | jq -r '
    def to_camel_case:
      split("_")
          | map( if length > 0 then (.[:1] | ascii_upcase) + .[1:] else "" end )
          | join(" ");

    [.parcels[] | {
      text: "\(.description): \(.tracking_status | to_camel_case)",
      subtext: "\(.tracking_location)",
      badge: "\(.carrier)",
      click: "/usr/bin/open \(
        if .carrier == "USPS" then "https://tools.usps.com/go/TrackConfirmAction?tLabels=\(.tracking_id)"
        elif .carrier == "UPS" then "https://www.ups.com/track?loc=en_US&tracknum=\(.tracking_id)"
        elif .carrier == "FedEx" then "https://www.fedex.com/apps/fedextrack/?tracknumbers=\(.tracking_id)"
        elif .carrier == "DHL" then "https://www.dhl.com/global-en/home/tracking.html?tracking-id=\(.tracking_id)"
        else "https://www.google.com/search?q=\(.carrier)+\(.tracking_id)"
        end
      )"
    }] | tojson')

top_menu_items='{"text": "Open OneTracker", "click": "/usr/bin/open https://onetracker.app/parcels"}'

delivered_pkg_ids=$(echo "$response" | jq -r '[.parcels[] | select(.tracking_status == "delivered") | .id] | join(" ")')
if [[ -n "$delivered_pkg_ids" ]]; then
  archive_cmd="$ARCHIVE_SH $delivered_pkg_ids"
  top_menu_items+=', {"text": "Archive delivered", "click": "'$archive_cmd'", "refresh": true}'
fi

top_menu_items+=', {"text": "-"}'
if [[ "$menu_items" == "[]" ]]; then
  top_menu_items+=', {"text": "No pakcages"}'
fi
menu_items=$(jq -s 'add' <(echo "[$top_menu_items]") <(echo "$menu_items"))

echo '
{
  "imagesymbol": "'$symbol'",
  "text": "",
  "menus": '$menu_items',
  "menuopen": "/bin/mv '$SNAPSHOT_FILE'.tmp '$SNAPSHOT_FILE'"
}'
