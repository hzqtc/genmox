#!/bin/bash

mpc="/opt/homebrew/bin/mpc"
if test ! -x "$mpc"; then
  echo '
  {
    "image": "",
    "altimage": "",
    "menus": [],
    "text": "Error mpc not found"
  }
  '
  exit 1
fi

# -f "%file%" asks MPC to return file name of the current track
mpd_status=$($mpc status -f "%file%" 2>&1)
if $(echo "$mpd_status" | grep -iq "error:"); then
  status="error"
fi

if [[ "$status" == "error" ]]; then
  echo '
  {
    "image": "",
    "altimage": "",
    "menus": [
      {
        "click": "/opt/homebrew/bin/brew services restart mpd",
        "text": "Restart MPD",
        "keyboard": "d",
      },
    ],
    "text": "MPD error"
  }
  '
  exit 0
fi

# if status doesn't contain [playing] or [paused] then mpd is stopped
if [[ "$mpd_status" =~ \[(playing|paused)\] ]]; then
  status=$(echo "$mpd_status" | grep -Eo "(playing|paused)")
  title=$(echo "$mpd_status" | head -n 1 )
  title=${title%.*} # remove file name extension
  title=${title#*/} # remove directory
  progress=$(echo "$mpd_status" | grep -Eo "[0-9]{1,2}:[0-9]{2}/[0-9]{1,2}:[0-9]{2}")
  menu_text="$title $progress"

  # Current track position in playlist
  current_pos=$(echo "$mpd_status" | grep -Eo "#[0-9]+/[0-9]+")
  current_pos=${current_pos#\#}
  current_pos=${current_pos%/*}
else
  status="stopped"
  menu_text="MPD Stopped"
  current_pos=0
fi

# Get the playlist
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

if [[ "$status" == "stopped" ]]; then
  control_menus='
    {
      "click": "",
      "text": "-",
      "keyboard": "",
    },
    {
      "click": "'$mpc' play",
      "text": "Play",
      "keyboard": "p",
    },'
  seek_menus=''
else
  control_menus='
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
    },'
  seek_menus='
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
    },'
fi

if $(echo "$mpd_status" | grep -Eoq "repeat: on"); then
  repeat=true
else
  repeat=false
fi
if $(echo "$mpd_status" | grep -Eoq "single: on"); then
  single=true
else
  single=false
fi

echo '
  {
    "image": "",
    "altimage": "",
    "menus": [
      {
        "click": "",
        "text": "Playlist Position: '$current_pos'/'$playlist_len'",
        "keyboard": "",
        "submenus": ['$playlist_menu_items'],
      },
      '$control_menus'
      '$seek_menus'
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
        "text": "Add All Tracks",
        "keyboard": "",
      },
      {
        "click": "'$mpc' clear",
        "text": "Clear Playlist",
        "keyboard": "",
      },
      {
        "click": "",
        "text": "-",
        "keyboard": "",
      },
      {
        "click": "'$mpc' shuffle",
        "text": "Shuffle Playlist",
        "keyboard": "",
      },
      {
        "click": "'$mpc' repeat",
        "text": "Repeat Mode",
        "keyboard": "",
        "checked": "'$repeat'",
      },
      {
        "click": "'$mpc' single",
        "text": "Single Mode",
        "keyboard": "",
        "checked": "'$single'",
      },
      {
        "click": "",
        "text": "-",
        "keyboard": "",
      },
      {
        "click": "/opt/homebrew/bin/brew services restart mpd",
        "text": "Restart MPD",
        "keyboard": "d",
      },
    ],
    "text": "'$menu_text'"
  }'

