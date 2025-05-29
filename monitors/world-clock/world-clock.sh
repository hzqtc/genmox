#!/usr/bin/env bash

time_zones=("Asia/Shanghai" "America/New_York" "Europe/Zurich")

get_time_in_zone() {
  local timezone=$1
  TZ="$timezone" date +"%I:%M%p"
}

get_date_in_zone() {
  local timezone=$1
  TZ="$timezone" date +"%b %d"
}

get_city_name() {
  local timezone=$1
  echo ${timezone#*/} | tr _ ' '
}

# Format timezone times into menu items in JSON
menu_items=""
for timezone in "${time_zones[@]}"; do
  time=$(get_time_in_zone "$timezone")
  date=$(get_date_in_zone "$timezone")
  city=$(get_city_name "$timezone")

  if [[ -n "$menu_items" ]]; then
    menu_items+=","
  fi
  menu_items+='
    {
        "click": "/usr/bin/open -a Clock",
        "text": "'$city' '$time'",
        "badge": "'$date'"
    }'
done

first_time_zone=${time_zones[0]}
hour=$(TZ="$first_time_zone" date +"%H")
if [ "$hour" -ge 6 ] && [ "$hour" -lt 20 ]; then
  image_symbol="sun.max"
elif [ "$hour" -ge 20 ] || [ "$hour" -lt 6 ]; then
  image_symbol="moon"
fi
echo '
  {
    "imagesymbol": "'$image_symbol'",
    "menus": ['$menu_items'],
    "text": "'$(get_city_name $first_time_zone)' '$(get_time_in_zone $first_time_zone)'"
  }
'
