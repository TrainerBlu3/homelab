#!/bin/bash
# Nightly encrypted backup of /opt/stacks -> local + npclab. Run by stack-backup.timer.
set -euo pipefail
DEST=/var/backups/stacks
KEEP_DAYS=7
OUT="$DEST/stacks-$(date +%F).tar.gz.age"
RECIPIENT=$(cat /etc/stack-backup/age.pub)
mkdir -p "$DEST"

mapfile -t STACKS < <(ls /opt/stacks)
start_all() { for s in "${STACKS[@]}"; do (cd "/opt/stacks/$s" && docker compose start >/dev/null 2>&1) || true; done; }
trap start_all EXIT

for s in "${STACKS[@]}"; do (cd "/opt/stacks/$s" && docker compose stop -t 30 >/dev/null 2>&1); done
tar --exclude='prometheus-data' --exclude='grafana-data/plugins' -czf - -C /opt stacks | age -r "$RECIPIENT" > "$OUT"
start_all; trap - EXIT

chmod 644 "$OUT"
runuser -u trainerblue -- scp -q "$OUT" npclab:backups/
find "$DEST" -name 'stacks-*.age' -mtime +"$KEEP_DAYS" -delete
runuser -u trainerblue -- ssh npclab "find ~/backups -name 'stacks-*.age' -mtime +$KEEP_DAYS -delete"
