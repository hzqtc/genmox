#!/bin/bash

mpc="/opt/homebrew/bin/mpc"
if test ! -x "$mpc"; then
  echo '
  {
    "image": "'$(pwd)'/error.png",
    "altimage": "'$(pwd)'/error_neg.png",
    "menus": [],
    "text": "Error mpc command not found"
  }
  '
  exit 1
fi

mpd_status=$($mpc status -f "%file%" 2>&1)
if [[ "$mpd_status" =~ "MPD error:" ]]; then
  status="error"
fi

if [[ "$status" == "error" ]]; then
  echo '
  {
    "image": "'$(pwd)'/error.png",
    "altimage": "'$(pwd)'/error_neg.png",
    "menus": [],
    "text": "'$mpd_status'"
  }
  '
  exit 0
fi

# if status doesn't contain [playing] or [paused] then mpd is stopped
if [[ "$mpd_status" =~ \[(playing|paused)\] ]]; then
  status=$(echo "$mpd_status" | grep -Eo "(playing|paused)")
else
  status="stopped"
  menu_text="MPD Stopped"
fi

if [[ "$status" != "stopped" ]]; then
  title=$(echo "$mpd_status" | head -n 1 )
  title=${title%.*}
  progress=$(echo "$mpd_status" | grep -Eo "[0-9]{1,2}:[0-9]{2}/[0-9]{1,2}:[0-9]{2}")
  menu_text="$title $progress"


  queue_menu_items=""
  IFS=$'\n'
  for track in $($mpc playlist -f "%file% (%position%)" | head -n 10); do
    position=$(echo $track | grep -Eo "\([0-9]+\)")
    position=${position#(}
    position=${position%)}
    queue_menu_items+='
      {
        "click": "'$mpc' play '$position'",
        "text": "'${track%.*}'",
        "keyboard": "",
      },
    '
    increment=$((increment + 1))
  done
fi


echo '
  {
    "image": "'$(pwd)'/'$status'.png",
    "altimage": "'$(pwd)'/'$status'_neg.png",
    "menus": ['$queue_menu_items'
      {
        "click": "",
        "text": "-",
        "keyboard": "",
      },
      {
        "click": "'$mpc' toggle",
        "text": "Toggle",
        "keyboard": "",
      },
      {
        "click": "'$mpc' stop",
        "text": "Stop",
        "keyboard": "",
      },
      {
        "click": "'$mpc' next",
        "text": "Next Track",
        "keyboard": "",
      },
      {
        "click": "'$mpc' prev",
        "text": "Previous Track",
        "keyboard": "",
      },
      {
        "click": "",
        "text": "-",
        "keyboard": "",
      },
      {
        "click": "'$mpc' seek +5",
        "text": "Fast Forward 5s",
        "keyboard": "",
      },
      {
        "click": "'$mpc' seek -5",
        "text": "Rewind 5s",
        "keyboard": "",
      },
      {
        "click": "'$mpc' seek +10",
        "text": "Fast Forward 10s",
        "keyboard": "",
      },
      {
        "click": "'$mpc' seek -10",
        "text": "Rewind 10s",
        "keyboard": "",
      },
      {
        "click": "",
        "text": "-",
        "keyboard": "",
      },
      {
        "click": "'$mpc' update",
        "text": "Update Database",
        "keyboard": "",
      },
      {
        "click": "'$mpc' add /",
        "text": "Add all tracks",
        "keyboard": "",
      },
      {
        "click": "'$mpc' clear",
        "text": "Clear Playlist",
        "keyboard": "",
      },
      {
        "click": "'$mpc' shuffle",
        "text": "Shuffle Playlist",
        "keyboard": "",
      },
    ],
    "text": "'$menu_text'"
  }
  '

