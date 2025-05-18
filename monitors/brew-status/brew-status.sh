#!/bin/bash

brew="/opt/homebrew/bin/brew"
notifier="/opt/homebrew/bin/terminal-notifier"

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
    "menus": [{"text": "Up to date"}]
  }'
else
  menuitems='
  {
    "click": "'$brew' upgrade",
    "text": "Upgrade all",
    "keyboard": "a",
    "refresh": true
  }, {
    "text": "-"
  },'
  while IFS= read -r pkg; do
    text=$(echo "$pkg" | sed -E 's/^(.*) \((.*)\) < (.*)$/\1: \2 => \3/')
    menuitems+='
    {
      "text": "'$text'"
    },'
  done <<< "$pkgs"
  echo '
  {
    "imagesymbol": "circle.fill",
    "text": "",
    "menus": ['$menuitems']
  }'

  if test -x "$notifier"; then
    $notifier \
      -group "homebrew-outdated-pkgs" \
      -title "Newer formula available" \
      -message "$pkgs" \
      -sound Glass \
      -sender com.apple.Terminal > /dev/null 2>&1
  fi
fi

