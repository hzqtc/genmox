#!/bin/bash

# This script depends on https://jqlang.org/ and https://www.gnu.org/software/parallel/

# Get a free key on https://finnhub.io/
API_KEY_FILE="$(dirname "$0")/.finnhub-key"
if [ ! -f "$API_KEY_FILE" ]; then
  echo "API key file '$API_KEY_FILE' not found."
  exit 1
fi
API_KEY=$(<"$API_KEY_FILE")

symbols=("GOOG" "AAPL" "META" "AMZN" "MSFT" "TSLA" "NVDA")

# Get stock quote and format into a short string: GOOG $189.64 +$12.30
stock_quote() {
  local symbol="$1"
  # API doc: https://finnhub.io/docs/api/quote
  local url="https://finnhub.io/api/v1/quote?symbol=${symbol}"
  json=$(curl -s -H "X-Finnhub-Token: $API_KEY" "$url")

  price=$(echo "$json" | jq -r '.c')
  change=$(echo "$json" | jq -r '.d')

  printf "%s \$%.2f %+.2f\n" "$symbol" "$price" "$change"
}

# Export for parallel to use
export -f stock_quote
export API_KEY

# Parallel removes '\n' so converting results to an array
quotes=()
while IFS= read -r line; do
  quotes+=("$line")
done < <(/opt/homebrew/bin/parallel -k stock_quote ::: "${symbols[@]}")

menu_item_json=()
i=1
for quote in "${quotes[@]}"; do
  symbol=$(echo "$quote" | awk '{print $1}')
  click="/usr/bin/open https://www.google.com/search?q=${symbol}+stock"

  json=$(jq -n \
    --arg click "$click" \
    --arg text "$quote" \
    --arg keyboard "$i" \
    '{click: $click, text: $text, keyboard: $keyboard}')

  menu_item_json+=("$json")
  ((i++))
done

menu_items=$(jq -s '.' <<< "${menu_item_json[*]}")

jq -n \
  --arg image "" \
  --arg altimage "" \
  --argjson menus "$menu_items" \
  --arg text "${quotes[0]}" \
  '{"image": $image, "altimage": $altimage, "menus": $menus, "text": $text}'

