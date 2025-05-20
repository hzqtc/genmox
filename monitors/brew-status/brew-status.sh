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
    "refresh": true
  }, {
    "text": "-"
  },'
  while IFS= read -r pkg; do
    # pkg is a string in "name (old_version) < new_version"
    name=${pkg% (*}
    new_version=${pkg#*< }
    brew_info=$($brew info --json $name)
    desc=$(echo $brew_info | jq -r '.[0] | .desc')
    url=$(echo $brew_info | jq -r '.[0] | .homepage')
    menuitems+='
    {
      "text": "'$name'",
      "subtext": "'$desc'",
      "badge": "'$new_version'",
      "click": "/usr/bin/open '$url'"
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

