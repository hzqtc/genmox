#!/usr/bin/env bash

brew="/opt/homebrew/bin/brew"
brew_upgrade="$(dirname $0)/brew-upgrade.as"
brew_cleanup="$(dirname $0)/brew-cleanup.as"
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
pkgs=$($brew outdated --quiet)

if [[ -z "$pkgs" ]]; then
  echo '
  {
    "imagesymbol": "circle",
    "text": "",
    "menus": [{"text": "Up to date"}, {"text": "Clean up", "click": "'$brew_cleanup'"}]
  }'
  exit 0
fi

get_pkg_menuitem() {
  local name="$1"
  local brew_info=$($brew info --json=v2 $name)
  local formulae=$(echo $brew_info | jq -r '.formulae[0]')
  local cask=$(echo $brew_info | jq -r '.casks[0]')
  if [[ $formulae != 'null' ]]; then
    local desc=$(echo $formulae | jq -r '.desc')
    local url=$(echo $formulae | jq -r '.homepage')
    local current_version=$(echo $formulae | jq -r '.installed[0].version')
    local new_version=$(echo $formulae | jq -r '.versions.stable')
  elif [[ $cask != 'null' ]]; then
    local desc=$(echo $cask | jq -r '.desc')
    local url=$(echo $cask | jq -r '.homepage')
    local current_version=$(echo $cask| jq -r '.installed')
    local new_version=$(echo $cask | jq -r '.version')
  fi
  echo '{
    "text": "'$name'",
    "subtext": "'$desc'",
    "badge": "'$current_version' → '$new_version'",
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

