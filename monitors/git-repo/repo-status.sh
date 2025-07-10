#!/usr/bin/env bash

required_cmds=(git jq parallel tokei)
for cmd in "${required_cmds[@]}"; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "$cmd is required" >&2
    exit 1
  fi
done

format_duration() {
  local seconds="$1"

  local weeks=$((seconds / 604800))
  local days=$(((seconds % 604800) / 86400))
  local hours=$(((seconds % 86400) / 3600))

  local duration=""
  if (( weeks > 0 )); then
    duration="${weeks}weeks"
  elif (( days > 0 )); then
    duration="${days}days"
  elif (( hours > 0 )); then
    duration="${hours}hours"
  fi

  if [[ -z "$duration" ]]; then
    echo "just now"
  else
    echo "$duration ago"
  fi
}

repo_status() {
  local repo="$1"
  local name=$(basename "$repo")
  local local_branch=""
  local remote_branch=""
  local ahead=0
  local behind=0
  local insertions=0
  local deletions=0
  local total_commits=""
  local time_since_last_commit=""
  local primary_lang=""

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

  read -r ins1 del1 <<< "$(parse_diff "$unstaged")"
  read -r ins2 del2 <<< "$(parse_diff "$staged")"

  insertions=$((ins1 + ins2))
  deletions=$((del1 + del2))

  # --- Check upstream status ---
  local_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  remote_branch=$(git rev-parse --abbrev-ref "$local_branch@{u}" 2>/dev/null)
  if [[ -n "$remote_branch" ]]; then
    git remote update -p &>/dev/null
    read -r ahead behind <<< "$(git rev-list --left-right --count "$local_branch...$remote_branch" 2>/dev/null)"
    ahead=${ahead:-0}
    behind=${behind:-0}
  fi

  # --- Commits stats ---
  total_commits=$(git rev-list --count HEAD 2>/dev/null || echo 0)
  if [[ "$total_commits" != "0" ]]; then
    # Time since last commit
    last_commit_unix=$(git log -1 --format=%ct)
    now=$(date +%s)
    seconds_since_last_commit=$((now - last_commit_unix))
    time_since_last_commit=$(format_duration "$seconds_since_last_commit")
  fi

  # --- Code stats ---
  tokei_json=$(tokei . --output json)
  # Primary language is the one with most lines of code
  primary_lang=$(echo "$tokei_json" \
    | jq -r 'del(.Total) | to_entries | map(select(.value.code > 0)) | if length == 0 then "" else max_by(.value.code).key end')

  # --- Calculate output values---
  local badge=""
  local text=""
  local subtext=""
  local click=""

  # text shows the sync status of remote branch
  if (( insertions > 0 || deletions > 0 )); then
    text="$name: Uncommitted (+$insertions / -$deletions)"
  elif [[ -n "$remote_branch" ]]; then
    if (( ahead > 0 || behind > 0 )); then
      text="$name: Unsynced ($ahead ahead / $behind behind)"
    else
      text="$name: Up to date"
    fi
  else
    text="$name: No remote repo set"
  fi

  # subtext shows commit stats
  if [[ "$total_commits" != "0" ]]; then
    subtext="$total_commits commits; last commit $time_since_last_commit"
  else
    subtext="No commits yet"
  fi

  # badge shows the primary language
  badge="$primary_lang"

  # Click opens the remote repo url
  remote_url=$(git config --get remote.origin.url || echo "")
  if [[ "$remote_url" == git@* ]]; then
    remote_url="https://${remote_url#git@}"
    remote_url="${remote_url/:/\/}"
    remote_url="${remote_url%.git}"
  elif [[ "$remote_url" == http* ]]; then
    remote_url="${remote_url%.git}"
  fi

  click="/usr/bin/open $remote_url"

  # --- Output as JSON ---
  # last_commit key is only used for sorting would be ignored by genmox
  jq -n --arg text "$text" \
    --arg click "$click" \
    --arg badge "$badge" \
    --arg subtext "$subtext" \
    --argjson last_commit "${last_commit_unix:-0}" \
    '{text: $text, click: $click, badge: $badge, subtext: $subtext, last_commit: $last_commit}'
}

export -f repo_status
export -f format_duration

# --- Find Git directories and process in parallel ---
DIR="${1:-.}"
menu_items=$(find "$DIR" -mindepth 1 -maxdepth 1 -type d -exec test -d '{}/.git' \; -print \
  | parallel repo_status \
  | jq -s 'sort_by(-.last_commit)')

all_up_to_date=$(echo "$menu_items" | jq 'all(.[]; (.text | contains("Up to date")))')
if [[ "$all_up_to_date" == "true" ]]; then
  symbol="checkmark.icloud"
else
  symbol="arrow.trianglehead.2.clockwise.rotate.90.icloud"
fi

jq -n --arg symbol "$symbol" --argjson menus "$menu_items" \
  '{imagesymbol: $symbol, text: "", menus: $menus}'
