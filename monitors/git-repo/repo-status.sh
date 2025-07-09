#!/usr/bin/env bash

DIR="${1:-.}"

export up_to_date_icon="✅"
export has_uncommited_change_icon="✏️"
export unsynced_icon="🔄"
export no_remote_icon="⚠️"

check_repo() {
  local repo="$1"
  local name=$(basename "$repo")
  local badge=$up_to_date_icon
  local text="$name: Up to date"
  local subtext=""
  local ahead=0
  local behind=0
  local insertions=0
  local deletions=0

  cd "$repo" || exit

  # --- Accumulate uncommitted (staged + unstaged) changes ---
  parse_diff() {
    local stat="$1"
    local ins=$(echo "$stat" | grep -o '[0-9]\+ insertions' | grep -o '[0-9]\+' || echo 0)
    local del=$(echo "$stat" | grep -o '[0-9]\+ deletions' | grep -o '[0-9]\+' || echo 0)
    echo $((ins)) $((del))
  }

  unstaged=$(git diff --shortstat 2>/dev/null)
  staged=$(git diff --shortstat --cached 2>/dev/null)

  read ins1 del1 <<< $(parse_diff "$unstaged")
  read ins2 del2 <<< $(parse_diff "$staged")

  insertions=$((ins1 + ins2))
  deletions=$((del1 + del2))

  if (( insertions > 0 || deletions > 0 )); then
    subtext="Uncommitted changes: +$insertions / -$deletions"
    badge=$has_uncommited_change_icon
  fi

  # --- Check upstream status ---
  local_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if upstream=$(git rev-parse --abbrev-ref "$local_branch@{u}" 2>/dev/null); then
    git remote update -p &>/dev/null
    read ahead behind <<< $(git rev-list --left-right --count "$local_branch...$upstream" 2>/dev/null)
    ahead=${ahead:-0}
    behind=${behind:-0}

    if (( ahead > 0 || behind > 0 )); then
      text="$name: $ahead ahead / $behind behind of remote"
      badge=$unsynced_icon
    fi
  else
    text="$name: No remote repo set"
    badge=$no_remote_icon
  fi

  click="/usr/bin/open $repo"

  # --- Output as JSON ---
  jq -n --arg text "$text" --arg click "$click" --arg badge "$badge" --arg subtext "$subtext" \
    '{text: $text, click: $click, badge: $badge, subtext: $subtext}'
}

export -f check_repo

# --- Find Git directories and process in parallel with preserved order ---
menu_items=$(find "$DIR" -mindepth 1 -maxdepth 1 -type d -exec test -d '{}/.git' \; -print | parallel check_repo | jq -s .)

all_up_to_date=$(echo "$menu_items" | jq --arg icon "$up_to_date_icon" 'all(.[]; .badge == $icon)')
if [[ "$all_up_to_date" == "true" ]]; then
  symbol="checkmark.circle.fill"
else
  symbol="flag.circle.fill"
fi

echo '
{
  "imagesymbol": "'$symbol'",
  "text": "",
  "menus": '$menu_items',
}'
