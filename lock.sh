#!/usr/bin/env bash

set -euo pipefail

if pgrep -x keepassxc >/dev/null; then
  timeout --kill-after=1s 3s keepassxc --lock >/dev/null 2>&1
fi
