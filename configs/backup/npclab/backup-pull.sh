#!/bin/bash
# Pull chadlab's encrypted stack backups to npclab. Run by backup-pull.timer as trainergreen.
# The key can only run `rrsync -ro /var/backups/stacks` on chadlab (forced command), so it can read
# archives and nothing else. --ignore-existing: a copy already here is never replaced.
set -euo pipefail
DEST="$HOME/backups"
KEEP=7
mkdir -p "$DEST"

rsync -a --ignore-existing --include='stacks-*.tar.gz.age' --exclude='*' \
  -e "ssh -F $HOME/.ssh/backup_pull_config" chadlab-backup:./ "$DEST/"

# Keep the newest $KEEP archives. Count-based on purpose: if chadlab stops producing backups,
# the last good ones are never aged out.
ls -1t "$DEST"/stacks-*.tar.gz.age | tail -n +$((KEEP + 1)) | xargs -r rm -f --

# Fail (-> ntfy) if the newest archive is older than 26h: chadlab stopped backing up, or this pull is broken.
# rsync -a keeps chadlab's mtime, so this measures when the backup was made, not when it was copied.
newest=$(ls -1t "$DEST"/stacks-*.tar.gz.age | head -1)
if [ -z "$(find "$newest" -mmin -1560)" ]; then
  echo "Newest backup is older than 26h: $(basename "$newest")" >&2
  exit 1
fi
