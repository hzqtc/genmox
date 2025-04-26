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
  current_pos=$(echo "$mpd_status" | grep -Eo "#[0-9]+/[0-9]+")
  current_pos=${current_pos#\#}
  current_pos=${current_pos%/*}

  plaplaylist_menu_items=""
  playlist_len=0
  IFS=$'\n'
  for track in $($mpc playlist -f "%file% (%position%)"); do
    track_pos=$(echo $track | grep -Eo "\([0-9]+\)")
    track_pos=${track_pos#(}
    track_pos=${track_pos%)}
    if [[ $current_pos == $track_pos ]]; then
      checked=true
    else
      checked=false
    fi

    playlist_menu_items+='
      {
        "click": "'$mpc' play '$track_pos'",
        "text": "'${track%.*}'",
        "keyboard": "",
        "checked": "'$checked'",
      },
    '

    playlist_len=$((playlist_len + 1))
  done
fi


echo '
  {
    "image": "'$(pwd)'/'$status'.png",
    "altimage": "'$(pwd)'/'$status'_neg.png",
    "menus": [
      {
        "click": "",
        "text": "Playlist Position: '$current_pos'/'$playlist_len'",
        "keyboard": "",
        "submenus": ['$playlist_menu_items'],
      },
      {
        "click": "",
        "text": "-",
        "keyboard": "",
      },
      {
        "click": "'$mpc' toggle",
        "text": "Toggle",
        "keyboard": "t",
      },
      {
        "click": "'$mpc' stop",
        "text": "Stop",
        "keyboard": "s",
      },
      {
        "click": "'$mpc' next",
        "text": "Next Track",
        "keyboard": "n",
      },
      {
        "click": "'$mpc' prev",
        "text": "Previous Track",
        "keyboard": "p",
      },
      {
        "click": "",
        "text": "-",
        "keyboard": "",
      },
      {
        "click": "'$mpc' seek +5",
        "text": "Fast Forward 5s",
        "keyboard": "f",
      },
      {
        "click": "'$mpc' seek -5",
        "text": "Rewind 5s",
        "keyboard": "r",
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

