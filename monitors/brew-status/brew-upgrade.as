#!/usr/bin/osascript

set upgradeCommand to "brew upgrade"

tell application "Terminal"
  if not (exists window 1) then
    do script upgradeCommand
  else
    do script upgradeCommand in window 1
  end if
  activate
end tell
