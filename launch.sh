#!/usr/bin/env bash

set -euo pipefail

window_address=$(hyprctl clients -j | jq -r '
  first(.[] | select((.class // "" | ascii_downcase) == "org.keepassxc.keepassxc") | .address) // empty
')

if [[ -n $window_address ]]; then
  hyprctl dispatch "hl.dsp.focus({ window = \"address:$window_address\" })" >/dev/null
else
  exec setsid uwsm-app -- gtk-launch org.keepassxc.KeePassXC
fi
