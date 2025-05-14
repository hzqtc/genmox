#!/bin/bash

brew="/opt/homebrew/bin/brew"
if test ! -x "$brew"; then
  echo '
  {
    "imagesymbol": "exclamationmark.triangle",
    "text": "Error brew not found"
  }'
  exit 1
fi

$brew update > /dev/null 2>&1
pkgs=$($brew outdated --verbose)

if [[ -z "$pkgs" ]]; then
  echo '
  {
    "imagesymbol": "circle",
    "text": "",
  }'
else
  menuitems='
  {
    "click": "'$brew' upgrade",
    "text": "Upgrade all",
    "keyboard": "a"
  }, {
    "text": "-"
  },'
  while IFS= read -r pkg; do
    pkg_name=${pkg%% *}
    text=$(echo "$pkg" | sed -E 's/^(.*) \((.*)\) < (.*)$/\1: \2 => \3/')
    menuitems+='
    {
      "click": "'$brew' upgrade '$pkg_name'",
      "text": "'$text'"
    },'
  done <<< "$pkgs"
  echo '
  {
    "imagesymbol": "circle.fill",
    "text": "",
    "menus": ['$menuitems']
  }'
fi

