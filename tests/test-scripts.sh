#!/usr/bin/env bash

set -euo pipefail

plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
export PATH="$test_dir/bin:$PATH"
export TEST_LOG="$test_dir/log"
mkdir "$test_dir/bin"

cat >"$test_dir/bin/hyprctl" <<'EOF'
#!/usr/bin/env bash
if [[ $1 == clients ]]; then
  printf '%s\n' "${TEST_CLIENTS:-[]}"
else
  printf 'hyprctl %s\n' "$*" >>"$TEST_LOG"
fi
EOF

cat >"$test_dir/bin/setsid" <<'EOF'
#!/usr/bin/env bash
printf 'setsid %s\n' "$*" >>"$TEST_LOG"
EOF

cat >"$test_dir/bin/pgrep" <<'EOF'
#!/usr/bin/env bash
exit "${TEST_PGREP_STATUS:-0}"
EOF

cat >"$test_dir/bin/timeout" <<'EOF'
#!/usr/bin/env bash
printf 'timeout %s\n' "$*" >>"$TEST_LOG"
exit "${TEST_TIMEOUT_STATUS:-0}"
EOF

cat >"$test_dir/bin/omarchy-system-lock" <<'EOF'
#!/usr/bin/env bash
printf 'session-lock\n' >>"$TEST_LOG"
EOF

chmod +x "$test_dir/bin/"*

export TEST_CLIENTS='[
  {"class":"org.keepassxc.KeePassXC","address":"0xfirst"},
  {"class":"org.keepassxc.KeePassXC","address":"0xsecond"}
]'
bash "$plugin_dir/launch.sh"
[[ $(<"$TEST_LOG") == *'address:0xfirst'* ]]

: >"$TEST_LOG"
export TEST_CLIENTS='[]'
bash "$plugin_dir/launch.sh"
[[ $(<"$TEST_LOG") == 'setsid uwsm-app -- gtk-launch org.keepassxc.KeePassXC' ]]

export TEST_CLIENTS='[{"class":"org.keepassxc.KeePassXC","title":"[Locked] - KeePassXC"}]'
[[ $(bash "$plugin_dir/status.sh") == locked ]]
export TEST_CLIENTS='[{"class":"org.keepassxc.KeePassXC","title":"Unlocked vault [Locked] - KeePassXC"}]'
[[ $(bash "$plugin_dir/status.sh") == unlocked ]]

: >"$TEST_LOG"
export TEST_TIMEOUT_STATUS=7
status=0
bash "$plugin_dir/lock-session.sh" || status=$?
[[ $status == 7 ]]
[[ $(sed -n '1p' "$TEST_LOG") == timeout* ]]
[[ $(sed -n '2p' "$TEST_LOG") == session-lock ]]

printf 'Script tests passed\n'
