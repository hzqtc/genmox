#!/usr/bin/env bash

brew="/opt/homebrew/bin/brew"
brew_upgrade="$(dirname $0)/brew-upgrade.as"
parallel="/opt/homebrew/bin/parallel"
notifier="/opt/homebrew/bin/terminal-notifier"

if test ! -x "$brew"; then
  echo '
  {
    "imagesymbol": "exclamationmark.triangle",
    "text": "Error brew not found"
  }'
  exit 1
fi

if test ! -x "$parallel"; then
  echo '
  {
    "imagesymbol": "exclamationmark.triangle",
    "text": "Error parallel not found"
  }'
  exit 1
fi

# Update brew and check for outdated packages
$brew update > /dev/null 2>&1
pkgs=$($brew outdated --verbose)

if [[ -z "$pkgs" ]]; then
  echo '
  {
    "imagesymbol": "circle",
    "text": "",
    "menus": [{"text": "Up to date"}]
  }'
  exit 0
fi

get_pkg_menuitem() {
  # pkg is a string in "name (old_version) < new_version"
  local pkg="$1"
  local name=${pkg% (*}
  local new_version=${pkg#*< }
  local brew_info=$($brew info --json $name)
  local desc=$(echo $brew_info | jq -r '.[0] | .desc')
  local url=$(echo $brew_info | jq -r '.[0] | .homepage')
  echo '{
    "text": "'$name'",
    "subtext": "'$desc'",
    "badge": "'$new_version'",
    "click": "/usr/bin/open '$url'"
  },'
}

# Export for visibility to parallel
export brew
export -f get_pkg_menuitem

pkg_menuitems=$(echo "$pkgs" | $parallel -k get_pkg_menuitem)
menuitems='
{
  "click": "'$brew_upgrade'",
  "text": "Upgrade all",
  "refresh": true
}, {
  "text": "-"
},'$pkg_menuitems

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

