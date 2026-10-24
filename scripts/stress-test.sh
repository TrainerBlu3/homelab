#!/usr/bin/env bash
# Stress test a Rock Pi and log peak temperature.
# Usage: ./stress-test.sh [minutes]   (default 30)
set -euo pipefail

MINUTES="${1:-30}"
LOG="stress-$(hostname)-$(date +%Y%m%d-%H%M).log"

command -v stress-ng >/dev/null || { echo "Install stress-ng: sudo apt install -y stress-ng"; exit 1; }

peak=0
(
  while true; do
    t=$(sort -n /sys/class/thermal/thermal_zone*/temp | tail -1)
    f=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq | tr '\n' ' ')
    echo "$(date +%T) temp=$((t / 1000))C freq=$f" >> "$LOG"
    sleep 5
  done
) &
MON=$!
trap 'kill $MON 2>/dev/null' EXIT

stress-ng --cpu 6 --vm 2 --vm-bytes 75% --timeout "${MINUTES}m" --metrics-brief

peak=$(grep -o 'temp=[0-9]*' "$LOG" | cut -d= -f2 | sort -n | tail -1)
echo "Done. Peak temp: ${peak}C. Log: $LOG"
