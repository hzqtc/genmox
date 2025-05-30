#!/usr/bin/osascript

set cleanupCommand to "brew cleanup --prune=all"

tell application "Terminal"
  if not (exists window 1) then
    do script cleanupCommand
  else
    do script cleanupCommand in window 1
  end if
  activate
end tell
