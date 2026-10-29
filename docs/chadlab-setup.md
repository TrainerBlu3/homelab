# chadlab setup (Lenovo ThinkCentre M80q Gen 1)

**Role:** Docker host (Dockge stacks), monitoring, update notifications.
**Hardware:** i7-10700T, 16GB DDR4 (2 SO-DIMM, max 64GB), 256GB NVMe (SK hynix PC711), 1× 2.5" SATA bay (empty), 1GbE.
**OS:** Linux Mint 22.3 (Ubuntu 24.04 "noble" base), text-mode boot.
**Access:** key-only SSH (`AllowUsers trainerblue`), Tailscale (`chadlab.<tailnet>.ts.net`, 100.91.58.90), LAN 192.168.1.167.

## Boot target

- Switched to text console: `sudo systemctl set-default multi-user.target`
- Undo: `sudo systemctl set-default graphical.target`

## Automatic security updates

- Package: `unattended-upgrades` (installed 2026-10-27)
- Schedule: `/etc/apt/apt.conf.d/20auto-upgrades` → both values `"1"` (daily)
- **Mint gotcha:** default `Allowed-Origins` uses `${distro_id}` = `Linuxmint`, which doesn't match Ubuntu's security repo, so nothing got installed. Added to `/etc/apt/apt.conf.d/50unattended-upgrades`:
  ```
  "Ubuntu:noble-security";
  "UbuntuESMApps:noble-apps-security";
  "UbuntuESM:noble-infra-security";
  ```
- Verify: `sudo unattended-upgrade --dry-run --debug 2>&1 | grep -i "allowed origins"` → must include `o=Ubuntu,a=noble-security`
- Log: `/var/log/unattended-upgrades/unattended-upgrades.log`
- Mint's own automation (`mintupdate-automation`) **disabled**: it duplicated unattended-upgrades.
- Kernel updates come from `noble-updates` → **manual**: `sudo apt full-upgrade && sudo reboot`, then `uname -r` + `systemctl --failed`.
- Reboots are never automatic. Check: `cat /var/run/reboot-required 2>/dev/null || echo "no reboot needed"`

## Weekly update reminder (ntfy)

- Script: `/usr/local/bin/update-check.sh` (upgradable count + reboot-required → ntfy push)
- Timer: `update-check.timer`, Sundays 10:00, `Persistent=true`
- Topic: private, in password manager (never in the repo)
- Check: `systemctl list-timers update-check.timer`, logs `journalctl -u update-check`

## Firmware

- `fwupd`: `fwupdmgr get-upgrades` → `sudo fwupdmgr update` → reboot → `fwupdmgr get-history`
- 2026-10-27: SSD firmware 41720C20 → 41730C20 (success)
- Firmware updates: at home, ideally on UPS.

## Tailscale

- `sudo tailscale up` (no `--accept-routes`: already on LAN; no `--ssh`: sshd stays in charge)
- `sudo tailscale set --auto-update`
- Key expiry disabled in admin console
- Health-check warning "peers are advertising routes but --accept-routes is false" is **expected**.

## Docker

- Stacks managed in Dockge, stored in `/opt/stacks/` → see [docker.md](docker.md)
- Content folders (served by apps): `/srv/library/{books,manga,articles}`, `/srv/inbox`
- node_exporter (port 9100) for Prometheus

## Cleanup

- `casper-md5check.service` failed every boot (Mint live-installer leftover) → `sudo systemctl mask casper-md5check.service` + `sudo systemctl reset-failed`
- `systemctl --failed` should be empty; anything listed is new and worth investigating.