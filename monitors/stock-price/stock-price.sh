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

  price=$(echo "$json" | jq -r '.c')
  change=$(echo "$json" | jq -r '.d')
  change_percent=$(echo "$json" | jq -r '.dp')

  echo $(jq -n \
    --arg symbol "$symbol" \
    --arg price "$price" \
    --arg change "$change" \
    --arg change_percent "$change_percent" \
    '{symbol: $symbol, price: $price, change: $change, change_percent: $change_percent}')
}

quote_color() {
  # Percent from -100 to 100
  local percent="$1"
  local abs_percent=$(echo "${percent#-}" | bc -l)

  # Default color when change is neutral (<1%)
  if (($(echo "$abs_percent < 1" | bc -l))); then
    echo ""
    return
  fi

  # Determine shade based on threshold
  local primary_shade
  local secondary_shade
  if (($(echo "$abs_percent < 4" | bc -l))); then
    primary_shade="A7"
    secondary_shade="00"
  else
    primary_shade="BD"
    secondary_shade="10"
  fi

  if (($(echo "$percent < 0" | bc -l))); then
    echo "${primary_shade}${secondary_shade}${secondary_shade}"
  else
    echo "${secondary_shade}${primary_shade}${secondary_shade}"
  fi
}

# Format quote json into a menu item
quote_menu_item() {
  local json="$1"

  local symbol=$(echo "$json" | jq -r '.symbol')
  local price=$(echo "$json" | jq -r '.price')
  local change=$(echo "$json" | jq -r '.change')
  local change_percent=$(echo "$json" | jq -r '.change_percent')

  local quote=$(printf "%s \$%.2f\n" "$symbol" "$price")
  local badge=$(printf "%+.2f%%\n" "$change_percent")
  local color=$(quote_color "$change_percent")
  local click="/usr/bin/open https://www.google.com/search?q=${symbol}+stock"

  echo $(jq -n \
    --arg click "$click" \
    --arg text "$quote" \
    --arg badge "$badge" \
    --arg textcolor "$color" \
    '{click: $click, text: $text, badge: $badge, textcolor: $textcolor}')
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
