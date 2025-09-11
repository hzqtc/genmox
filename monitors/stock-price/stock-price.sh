#!/usr/bin/env bash

# This script depends on https://jqlang.org/ and https://www.gnu.org/software/parallel/

# Get a free key on https://finnhub.io/
API_KEY_FILE="$(dirname "$0")/.finnhub-key"
if [ ! -f "$API_KEY_FILE" ]; then
  echo '{"text": "API key file not found"}'
  exit 1
fi
API_KEY=$(<"$API_KEY_FILE")

symbols=("$@")
if [ ${#symbols[@]} -eq 0 ]; then
  echo '{"text": "No tickers specified"}'
  exit 1
fi

# Get stock quote and format into a json string
stock_quote() {
  local symbol="$1"
  # API doc: https://finnhub.io/docs/api/quote
  local url="https://finnhub.io/api/v1/quote?symbol=${symbol}"
  local json=$(curl -s -H "X-Finnhub-Token: $API_KEY" "$url")

  jq -n -c \
    --arg symbol "$symbol" \
    --arg price "$(echo "$json" | jq -r '.c')" \
    --arg change "$(echo "$json" | jq -r '.d')" \
    --arg change_percent "$(echo "$json" | jq -r '.dp')" \
    --arg open "$(echo "$json" | jq -r '.o')" \
    --arg prev_close "$(echo "$json" | jq -r '.pc')" \
    '{symbol: $symbol, price: $price, change: $change, change_percent: $change_percent, open: $open, prev_close: $prev_close}'
}

# Format quote json into a menu item
quote_menu_item() {
  local json="$1"

  local symbol=$(echo "$json" | jq -r '.symbol')
  local price=$(echo "$json" | jq -r '.price')
  local change=$(echo "$json" | jq -r '.change')
  local change_percent=$(echo "$json" | jq -r '.change_percent')
  local open=$(echo "$json" | jq -r '.open')
  local prev_close=$(echo "$json" | jq -r '.prev_close')

  local quote=$(printf "%s \$%.2f\n" "$symbol" "$price")
  local subtext=$(printf "Previous close: $%.2f Open: $%.2f" "$open" "$prev_close")
  local badge=$(printf "%+.2f (%+.2f%%)\n" "$change" "$change_percent")
  local color
  if [[ "$change" == -* ]]; then
    color="FF9E6D"
  else
    color="66CC99"
  fi
  local click="/usr/bin/open https://www.google.com/search?q=${symbol}+stock"

  jq -n -c \
    --arg click "$click" \
    --arg text "$quote" \
    --arg subtext "$subtext" \
    --arg badge "$badge" \
    --arg color "$color" \
    '{click: $click, text: $text, subtext: $subtext, badge: $badge, imagecolor: $color}'
}

# Export for parallel to use
export -f stock_quote
export API_KEY

# Parallel removes '\n' so converting results to an array
quote_jsons=()
while IFS= read -r line; do
  quote_jsons+=("$line")
done < <(/opt/homebrew/bin/parallel -k stock_quote ::: "${symbols[@]}")

menu_item_json=()
for quote_json in "${quote_jsons[@]}"; do
  menu_item_json+=("$(quote_menu_item "$quote_json")")
done

menu_items=$(printf "%s\n" "${menu_item_json[@]}" | jq -s '.')

text=$(echo "${menu_item_json[0]}" | jq -r '.text')
change=$(echo "${menu_item_json[0]}" | jq -r '.badge')
if [[ "$change" == +* ]]; then
  symbol="chart.line.uptrend.xyaxis"
else
  symbol="chart.line.downtrend.xyaxis"
fi
jq -n \
  --argjson menus "$menu_items" \
  --arg text "$text" \
  --arg symbol "$symbol" \
  '{"menus": $menus, "text": $text, "imagesymbol": $symbol}'
