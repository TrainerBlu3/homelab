# Maintenance

## Update policy

| What | How | Why |
|---|---|---|
| Security updates (Pis) | **Automatic**, via `unattended-upgrades` | Low risk, high urgency |
| Kernel / device tree / bootloader / firmware | **Manual**: blacklisted from automatic updates ([config](../configs/apt/51unattended-upgrades-local)) | A bad kernel or DTB can stop an SBC booting, and a box that won't boot can't be fixed over SSH |
| Kernel rollout order | **npclab first (canary)**, verify, then choppedlab | Prove the update on the less critical box |
| Tailscale | Self-updates (`tailscale set --auto-update`) | VPN security fixes matter |
| chadlab (Mint) | **Automatic security only**, via `unattended-upgrades` (+ `Ubuntu:noble-security` origins); full upgrades manual; weekly ntfy reminder | Same policy as the Pis; Mint's own automation disabled (was a duplicate) |
| Device firmware (BIOS/SSD) | **Manual**, `fwupdmgr get-upgrades` → `sudo fwupdmgr update` | Riskier than packages; at home, plugged in, ideally on UPS |
| Reboots | Never both Pis at once | DNS redundancy |

Customisations go in **drop-in files** (`*.d/`), never in the package defaults, so upgrades don't raise config-file conflicts and settings survive.
**Blacklist vs hold:** the kernel block is an unattended-upgrades *blacklist*, so automatic runs skip it but manual `apt full-upgrade` still installs it (which the canary routine needs). `apt-mark showhold` is empty by design. Check with `apt-config dump | grep -A6 Package-Blacklist`. The Armbian banner's "Kernel upgrade enabled" refers to Armbian's own setting, not this.

## Manual kernel update (per Pi)

```bash
tmux new -s upgrade                       # survives SSH drops
sudo apt update
apt list --upgradable                     # review first
sudo apt full-upgrade -y && sudo reboot
```
After the reboot:
```bash
uname -r
systemctl --failed
sudo journalctl -b -p err --no-pager | diff ~/baseline-errors.txt -
grep -E ' (upgrade|install) linux-image' /var/log/dpkg.log | tail -2
sudo journalctl -b -p err --no-pager > ~/baseline-errors.txt   # new baseline
```

## Routine checks

| Task | Frequency | Command |
|---|---|---|
| Full updates | Every 1–2 weeks | Manual kernel update (above) |
| Boot errors vs baseline | After any reboot | `sudo journalctl -b -p err --no-pager \| diff ~/baseline-errors.txt -` |
| Failed services | Monthly | `systemctl --failed` |
| Disk space | Monthly | `df -h` |
| Tailscale health | Monthly | `tailscale status` |
| Clock sync | Monthly | `timedatectl` |
| Dust cleaning | Every 3 months | Power off; compressed air through vents and heatsinks |
| Pending updates / reboot needed | Weekly (automatic) | `update-check` timer → ntfy push (Sun 10:00) |
| Firmware updates | Monthly | `fwupdmgr get-upgrades` |

## Known-normal boot errors (baseline)

Both Pis log the same harmless lines every boot:
- `rockchip-pcie ... link training timeout` / `error -110` (`ETIMEDOUT`): empty PCIe/M.2 slot
- `brcmfmac ...`: Wi-Fi/Bluetooth firmware (unused)
- `ASoC: DAPM unknown pin Headphones`: audio codec (headless)
- `90-alsa-restore.rules ... GOTO`: sound config quirk
- `systemd-tmpfiles ... file flags`: unsupported file attribute

Anything else is new and worth investigating.

## chadlab: known/fixed boot items
- `casper-md5check.service` failed every boot (Mint live-installer leftover) → masked 2026-10-28.

## Planned automation

- ~~Health-check script on a systemd timer, alerting by ntfy~~ Update check done on chadlab (`update-check.timer` → ntfy). Extend to Pis + add health checks (disk, temp, failed services)
- Uptime Kuma (up/down monitoring)
- Ansible playbook for updates across all three boxes

## Log

| Date | Box | Task | Notes |
|---|---|---|---|
| 2026-10-24 | both Pis | Security updates automated | unattended-upgrades + kernel blacklist |
| 2026-10-24 | npclab → choppedlab | Full upgrade (70 pkgs) | Canary order. Kernel pkg 26.8.1 → 26.8.3 (still 6.18.44). Clean boots |
| 2026-10-24 | choppedlab | Pi-hole installed | Quad9 upstream, listening mode ALL |
| 2026-10-24 | Telus hub | IPv6 disabled | Closes IPv6 DNS leak around Pi-Hole (Telus resolver was answering via IPv6). Verified: Laptop DNS only Pi-hole, doubleclick -> 0.0.0.0, Tailscale OK over IPv4 |
| 2026-10-24 | laptop, chadlab | SSH client config | Aliases for all boxes, keep-alive defaults |
| 2026-10-24 | chadlab | Automatic updates enabled | mintupdate-automation upgrade + autoremove; manual reboots |
| 2026-10-27 | chadlab | unattended-upgrades | Installed; added Ubuntu:noble-security origins (Mint distro_id mismatch); dry run OK |
| 2026-10-27 | chadlab | boot target | set-default multi-user.target (text console) |
| 2026-10-27 | choppedlab | iphone ssh | Termius ED25519 key (iphone-14) added; connects via tailnet IP 100.67.89.105 |
| 2026-10-27 | choppedlab | authorized_keys cleanup | Removed duplicate iphone key; renamed to titorick-laptop / chadlab-trainerblue / iphone14-termius (2026-10) |
| 2026-10-27 | all | termius hosts | iPhone Termius: choppedlab (100.x), chadlab + npclab (LAN IP via subnet route); verified key fingerprints match on all boxes |
| 2026-10-27 | chadlab | update policy | Disabled mintupdate-automation (duplicate of unattended-upgrades). Security-only auto; full upgrades manual |
| 2026-10-27 | choppedlab | pihole privacy | level 2 + 30-day retention confirmed; switching to level 0 for temporary blocklist tuning |
| 2026-10-27 | tailnet | tailscale dns | Global nameserver = choppedlab Pi-hole (100.67.89.105), override on; verified iPhone via dnsleaktest + on.quad9.net |
| 2026-10-27 | choppedlab | pihole lists | HaGeZi Pro, Gambling medium, TIF Mini, DoH + Perflyst Smart-TV; gravity rebuilt |
| 2026-10-28 | chadlab | update reminder | systemd timer update-check (Sun 10:00) -> ntfy push (private topic); iOS push fixed by reinstall/resubscribe |
| 2026-10-28 | chadlab | firmware + upgrade | SK hynix PC711 SSD firmware 41720C20 -> 41730C20 via fwupd; 7 apt pkgs |
| 2026-10-28 | chadlab | tailscale | Joined tailnet (100.91.58.90); key expiry off; no --accept-routes, no --ssh |
| 2026-10-28 | npclab | tailscale | Joined tailnet (100.103.67.98) as backup subnet router; route approval + failover test pending |
| 2026-10-28 | all | ssh/termius names | Hosts use <box>.<tailnet>.ts.net (MagicDNS) on laptop + Termius |
| 2026-10-28 | chadlab | cleanup | Masked casper-md5check (live-ISO leftover); kernel 7.0.0-42 confirmed; systemctl --failed clean |
| 2026-10-28 | npclab | subnet failover | choppedlab tailscale down (3-min self-restore); laptop on school Wi-Fi reached hub via npclab (TcpTestSucceeded True). HA remote access verified |
| 2026-10-28 | tailnet | dns failover | choppedlab offline 5 min; laptop (school Wi-Fi) resolved example.org + wikipedia.org via npclab Pi-hole. DNS HA verified |
| 2026-10-28 | chadlab | uptime-kuma | v2 (SQLite, dns: both Pi-holes); 4 monitors (2 DNS, 2 HTTP, retries 2) -> ntfy Homelab Alerts; npclab outage test: down + up alerts received |
| 2026-10-28 | chadlab | stacks | nebula-sync pinned v0.11.3 + diun labels; |
| 2026-10-28 | chadlab | stacks + docker doc + profile | nebula-sync pinned v0.11.3 + diun labels; uptime-kuma v2; diun added; 4 stacks synced to configs/ via hlstacks; docs/docker.md; profile copy updated (tailnet redacted) |
| 2026-10-28 | all | baseline | Pre-monitoring baseline for comparison once Prometheus/Grafana is running |
| 2026-10-28 | chadlab | doc fix | rebuilt chadlab-setup.md (escaped markdown) and added Tailscale, firmware, update reminder, Docker, cleanup sections |
| 2026-10-28 | all | prometheus + grafana | Metrics for all 3 boxes via node_exporter, 15-day retention, dashboard 1860; ufw rule for container -> host 9100; Kuma monitors for both |
| 2026-10-28 | chadlab | gluetun + qBittorrent | Proton Free WG via gluetun, DoH Quad9 + surveillance blocklist, qBit bound to tun0; kill switch verified; Kuma monitors added. Why: VPN-only egress for torrent client |
| 2026-10-29 | chadlab | stack backups | nightly age-encrypted stack backups to npclab. Kuma/Grafana had no recoverable copy state so we added one. Restore drill passed |
| 2026-10-29 | chadlab | suwayomi isolated deploy | Suwayomi with full isolation (own net, egress+host blocked, read-only, UID 1500, no sources); it tests zero-trust pattern on a container that needs nothing. Rollback: compose down; systemctl disable suwayomi-egress-block; ufw delete deny from 172.30.50.0/24; rm -r /opt/stacks/suwayomi |
