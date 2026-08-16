#!/usr/bin/env bash

set -euo pipefail

hyprctl clients -j | jq -r '
  map(select((.class // "" | ascii_downcase) == "org.keepassxc.keepassxc"))
  | if length == 0 then "stopped"
    elif any(.[]; (.title // "") == "[Locked] - KeePassXC") then "locked"
    elif any(.[]; (.title // "") | endswith(" - KeePassXC")) then "unlocked"
    else "running"
    end
'
