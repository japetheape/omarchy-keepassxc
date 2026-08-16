#!/usr/bin/env bash

set -euo pipefail

plugin_dir=${BASH_SOURCE[0]%/*}
lock_status=0
bash "$plugin_dir/lock.sh" || lock_status=$?
omarchy-system-lock
exit "$lock_status"
