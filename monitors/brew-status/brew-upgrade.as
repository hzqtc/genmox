#!/usr/bin/osascript

tell application "Terminal"
  if not (exists window 1) then
    do script "brew upgrade"
  else
    do script "brew upgrade" in window 1
  end if
  activate
end tell
