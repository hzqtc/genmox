#!/usr/bin/env bash

time_zones=("$@")
if [ ${#time_zones[@]} -eq 0 ]; then
  echo '{"text": "No timezones specified"}'
  exit 1
fi

time_in_zone() {
  local timezone=$1
  TZ="$timezone" date +"%I:%M%p"
}

date_in_zone() {
  local timezone=$1
  TZ="$timezone" date +"%b %d"
}

city_name() {
  local timezone=$1
  echo ${timezone#*/} | tr _ ' '
}

# "5:34:50 AM" => "5:34AM"
format_time() {
  echo "$1" | sed -E 's/:[0-9]{2} (AM|PM)$/\1/'
}

# "5:34:50 AM" => seconds since epoch
to_epoch() {
  local tz="$1"
  local time="$2"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS (BSD date)
    TZ="$tz" date -j -f "%I:%M:%S %p" "$time" +%s
  else
    # Linux (GNU date)
    TZ="$tz" date -d "$time" +%s
  fi
}

now_epoch() {
  local tz="$1"
  TZ="$tz" date +%s
}

# Format timezone into menu items in JSON
menu_item_for_zone() {
  local timezone=$1
  time=$(time_in_zone "$timezone")
  date=$(date_in_zone "$timezone")
  city=$(city_name "$timezone")

  geocoding_response=$(curl -s "https://nominatim.openstreetmap.org/search?city=${city// /+}&format=json&limit=1")
  lat=$(echo "$geocoding_response" | jq -r '.[0].lat')
  lng=$(echo "$geocoding_response" | jq -r '.[0].lon')

  sun_response=$(curl -s "https://api.sunrisesunset.io/json?lat=$lat&lng=$lng")
  sunrise=$(echo $sun_response | jq -r '.results.sunrise')
  sunset=$(echo $sun_response | jq -r '.results.sunset')

  sunrise_fmt=$(format_time "$sunrise")
  sunset_fmt=$(format_time "$sunset")

  # Convert to seconds since epoch
  sunrise_sec=$(to_epoch "$timezone" "$sunrise")
  sunset_sec=$(to_epoch "$timezone" "$sunset")
  # Duration in seconds
  diff=$((sunset_sec - sunrise_sec))
  hours=$((diff / 3600))
  minutes=$(((diff % 3600) / 60))

  now_sec=$(now_epoch "$timezone")
  if ((now_sec >= sunrise_sec && now_sec <= sunset_sec)); then
    daynight="day"
    badge="☀️ $date"
  else
    daynight="night"
    badge="🌙 $date"
  fi

  echo '
    {
        "click": "/usr/bin/open https://time.is/'${city// /_}'",
        "text": "'$time' '$city'",
        "subtext": "Sun: ↑'$sunrise_fmt' ↓'$sunset_fmt' ('$hours'h'$minutes'm)",
        "badge": "'$badge'",
        "daynight": "'$daynight'"
    }'
}

export -f menu_item_for_zone time_in_zone date_in_zone city_name format_time to_epoch now_epoch
menu_item_jsons=$(/opt/homebrew/bin/parallel -k menu_item_for_zone ::: "${time_zones[@]}")

# Convert to json array
menu_items=$(printf "%s\n" "${menu_item_jsons[@]}" | jq -s '.')

first_item_text=$(echo $menu_items | jq -r ".[0].text")
first_item_daynight=$(echo $menu_items | jq -r ".[0].daynight")
if [ "$first_item_daynight" == "day" ]; then
  image_symbol="sun.max"
elif [ "$first_item_daynight" == "night" ]; then
  image_symbol="moon"
fi
echo '
  {
    "imagesymbol": "'$image_symbol'",
    "menus": '$menu_items',
    "text": "'$first_item_text'"
  }'
