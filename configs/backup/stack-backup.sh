#!/bin/bash
# Nightly encrypted backup of /opt/stacks -> /var/backups/stacks. Run by stack-backup.timer.
# Off-box copy: npclab PULLS these files (configs/backup/npclab/). chadlab holds no credentials
# for npclab, so a compromised chadlab can't delete or overwrite the off-box copies.
set -euo pipefail
DEST=/var/backups/stacks
KEEP_DAYS=7
OUT="$DEST/stacks-$(date +%F).tar.gz.age"
RECIPIENT=$(cat /etc/stack-backup/age.pub)
PUSH_URL_FILE=/etc/stack-backup/kuma-push.url
mkdir -p "$DEST"

mapfile -t STACKS < <(ls /opt/stacks)
start_all() { for s in "${STACKS[@]}"; do (cd "/opt/stacks/$s" && docker compose start >/dev/null 2>&1) || true; done; }
trap start_all EXIT

for s in "${STACKS[@]}"; do (cd "/opt/stacks/$s" && docker compose stop -t 30 >/dev/null 2>&1); done
# Write to .tmp, then rename: npclab only pulls *.age, so it never copies a half-written archive
tar --exclude='prometheus-data' --exclude='grafana-data/plugins' -czf - -C /opt stacks | age -r "$RECIPIENT" > "$OUT.tmp"
mv "$OUT.tmp" "$OUT"
start_all; trap - EXIT

# 644 is fine: the archive is encrypted, and npclab's read-only pull runs as trainerblue
chmod 644 "$OUT"
find "$DEST" -name 'stacks-*.age' -mtime +"$KEEP_DAYS" -delete

# Every service in every stack must be running again (up to 2 min for slow starters like gluetun),
# otherwise the backup counts as failed -> OnFailure -> ntfy
not_running() {
  local s want have bad=""
  for s in "${STACKS[@]}"; do
    want=$(cd "/opt/stacks/$s" && docker compose config --services | wc -l)
    have=$(cd "/opt/stacks/$s" && docker compose ps --status running --services | wc -l)
    [ "$want" -eq "$have" ] || bad="$bad $s"
  done
  echo "$bad"
}
bad=""
for _ in $(seq 12); do
  bad=$(not_running)
  [ -z "$bad" ] && break
  sleep 10
done
if [ -n "$bad" ]; then
  echo "Backup written, but these stacks are not fully running:$bad" >&2
  exit 1
fi

# Success heartbeat -> Uptime Kuma push monitor (expects one per ~25h; silence = alert).
# Kuma was just restarted with everything else, so retry while it comes up.
# A failed push doesn't fail the backup: Kuma alerts on the missing heartbeat anyway.
if [ -r "$PUSH_URL_FILE" ]; then
  curl -fsS -m 15 --retry 18 --retry-delay 10 --retry-connrefused --retry-all-errors -o /dev/null "$(cat "$PUSH_URL_FILE")" \
    || echo "warning: Kuma heartbeat push failed" >&2
else
  echo "warning: $PUSH_URL_FILE missing, no heartbeat sent" >&2
fi
