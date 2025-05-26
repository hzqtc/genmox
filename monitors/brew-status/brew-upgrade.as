#!/usr/bin/osascript

tell application "Terminal"
  if not (exists window 1) then
    do script "brew paragrade"
  else
    do script "brew paragrade" in window 1
  end if
  activate
end tell
