#!/usr/bin/env bash
set -euo pipefail

# CPU percentages from ps are per core; normalize against logical CPU count.
# Refuse new compiler/test processes at 50% total host CPU utilization.
appui_cpu_count=$(sysctl -n hw.logicalcpu)
appui_cpu_usage=$(ps -A -o %cpu= | awk '{ total += $1 } END { printf "%.0f", total }')
appui_cpu_percent=$((appui_cpu_usage / appui_cpu_count))
echo "CPU utilization: ${appui_cpu_percent}% (limit: 50%)."
if ((appui_cpu_percent >= 50)); then
  echo 'CPU load is high; defer compilation, tests and preview startup.' >&2
  exit 75
fi
