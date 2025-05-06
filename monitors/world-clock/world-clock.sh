#!/bin/bash

time_zones=("Asia/Shanghai" "America/New_York" "Europe/Zurich")

get_time_in_zone() {
  local timezone=$1
  # Set the timezone and get the current time in format "Apr 14 3:14PM"
  current_time=$(TZ="$timezone" date +"%b %d %I:%M%p")
  # Convert timezone to city name
  city=`echo ${timezone#*/} | tr _ ' '`
  echo "$city: $current_time"
}

# Format timezone times into menu items in JSON
menu_items=""
for timezone in "${time_zones[@]}"; do
  formatted_time=$(get_time_in_zone "$timezone")
  menu_items+='
    {
        "click": "/usr/bin/open -a Clock",
        "text": "'$formatted_time'",
        "keyboard": "",
    },
  '
done

echo '
  {
    "image": "",
    "altimage": "",
    "menus": ['$menu_items'],
    "text": "'$(get_time_in_zone ${time_zones[0]})'"
  }
'
