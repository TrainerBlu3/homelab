# Backups



## What

Nightly 03:30 (`stack-backup.timer`): stop stacks → tar `/opt/stacks` (excl. `prometheus-data`, `grafana-data/plugins`) → age-encrypt → `/var/backups/stacks` on chadlab + `\~/backups` on npclab. 7-day retention. Failure → ntfy Homelab Alerts.



Files: `configs/backup/`. Key material is NOT in the repo:

- `/etc/stack-backup/age.pub`: public key (encrypt only)

- `/etc/stack-backup/ntfy.url`: alert URL (600)

- Private key: password manager, "age – chadlab backups"



## Restore (full)

1\. Get the newest `.age` file (chadlab, or npclab if chadlab is dead)

2\. Key into RAM: `read -rsp "key: " k; printf '%s\\n' "$k" | tr -d '\\r ' > /dev/shm/age.key; unset k`

3\. `sudo age -d -i /dev/shm/age.key stacks-DATE.tar.gz.age | sudo tar -xz -C /opt`

4\. `shred -u /dev/shm/age.key`

5\. `cd /opt/stacks/<stack> \&\& docker compose up -d` for each; Grafana re-downloads plugins on start



## Drill (monthly)

Decrypt → list (`tar -tz`) → extract kuma + grafana to `/tmp/restore` → `sqlite3 ... "PRAGMA integrity_check"` + counts → shred key, rm restore.



| Date | Result |

|---|---|

| 2026-10-29 | Pass: kuma ok/8 monitors, grafana ok/1 dashboard (in `resource` table) |

