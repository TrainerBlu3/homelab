# Backups

## What

| Step | Where | When |
|---|---|---|
| Stop stacks → tar `/opt/stacks` (excl. `prometheus-data`, `grafana-data/plugins`) → age-encrypt → `/var/backups/stacks` | chadlab, `stack-backup.timer` | 03:30 |
| Check every stack is running again → push heartbeat to Uptime Kuma | chadlab, end of `stack-backup.sh` | after backup |
| **Pull** new archives (read-only key) → `~/backups`, keep newest 7, alert if newest > 26h old | npclab, `backup-pull.timer` | 04:30 |

Alerts: chadlab failure → ntfy "chadlab backup FAILED"; npclab failure or stale backup → ntfy "npclab backup pull FAILED"; no heartbeat for 25h → Kuma "chadlab backup" push monitor.

**Why pull, not push:** chadlab holds no credentials for npclab. Its archives are readable by npclab's key (forced `rrsync -ro`), and npclab never replaces a copy it already has (`--ignore-existing`). A compromised chadlab can't delete or overwrite the off-box copies.

Files: `configs/backup/` (chadlab) and `configs/backup/npclab/`. Key material is NOT in the repo:

| File | Box | Mode |
|---|---|---|
| `/etc/stack-backup/age.pub` | chadlab | public key (encrypt only) |
| `/etc/stack-backup/ntfy.url` | chadlab | 600 root |
| `/etc/stack-backup/kuma-push.url` | chadlab | 600 root, full push URL from Kuma |
| `/etc/backup-pull/ntfy.url` | npclab | 600 root |
| `~/.ssh/chadlab_backup_pull` | npclab | 600 trainergreen, no passphrase (used by a timer) |
| age private key | password manager | "age – chadlab backups" |

## Restore (full)

Copy commands from the code block below, never from the rendered page.

```bash
# 1. Newest archive: chadlab /var/backups/stacks, or npclab ~/backups if chadlab is dead
ls -1t /var/backups/stacks/stacks-*.age | head -1

# 2. Private key into RAM only. umask 077 so the file is never readable by other users
( umask 077; read -rsp "key: " k; echo; printf '%s\n' "$k" | tr -d '\r ' > /dev/shm/age.key; unset k )

# 3. Decrypt + extract
sudo age -d -i /dev/shm/age.key stacks-DATE.tar.gz.age | sudo tar -xz -C /opt

# 4. Remove the key
shred -u /dev/shm/age.key

# 5. Start each stack (Grafana re-downloads plugins on start)
cd /opt/stacks/<stack> && docker compose up -d
```

On a fresh box, restore order for the isolated stacks still applies (docker.md): networks script → squid → suwayomi.

## Drill (monthly)

Decrypt → list (`tar -tz`) → extract kuma + grafana to `/tmp/restore` → `sqlite3 ... "PRAGMA integrity_check"` + counts → shred key, rm restore. Use an archive **from npclab** at least every other month, so the off-box copy is proven too.

| Date | Result |
|---|---|
| 2026-10-29 | Pass: kuma ok/8 monitors, grafana ok/1 dashboard (in `resource` table) |
