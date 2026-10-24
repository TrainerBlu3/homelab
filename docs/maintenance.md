# Maintenance

## Update policy

| What | How | Why |
|---|---|---|
| Security updates (Pis) | **Automatic**, via `unattended-upgrades` | Low risk, high urgency |
| Kernel / device tree / bootloader / firmware | **Manual**: blacklisted from automatic updates ([config](../configs/apt/51unattended-upgrades-local)) | A bad kernel or DTB can stop an SBC booting, and a box that won't boot can't be fixed over SSH |
| Kernel rollout order | **npclab first (canary)**, verify, then choppedlab | Prove the update on the less critical box |
| Tailscale | Self-updates (`tailscale set --auto-update`) | VPN security fixes matter |
| chadlab (Mint) | Update Manager, automatic security updates | |
| Reboots | Never both Pis at once | DNS redundancy |

Customisations go in **drop-in files** (`*.d/`), never in the package defaults, so upgrades don't raise config-file conflicts and settings survive.

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

## Known-normal boot errors (baseline)

Both Pis log the same harmless lines every boot:
- `rockchip-pcie ... link training timeout` / `error -110` (`ETIMEDOUT`): empty PCIe/M.2 slot
- `brcmfmac ...`: Wi-Fi/Bluetooth firmware (unused)
- `ASoC: DAPM unknown pin Headphones`: audio codec (headless)
- `90-alsa-restore.rules ... GOTO`: sound config quirk
- `systemd-tmpfiles ... file flags`: unsupported file attribute

Anything else is new and worth investigating.

## Planned automation

- Health-check script on a systemd timer, alerting by ntfy
- Uptime Kuma (up/down monitoring)
- Ansible playbook for updates across all three boxes

## Log

| Date | Box | Task | Notes |
|---|---|---|---|
| 2026-10-24 | both Pis | Security updates automated | unattended-upgrades + kernel blacklist |
| 2026-10-24 | npclab → choppedlab | Full upgrade (70 pkgs) | Canary order. Kernel pkg 26.8.1 → 26.8.3 (still 6.18.44). Clean boots |
| 2026-10-24 | choppedlab | Pi-hole installed | Quad9 upstream, listening mode ALL |
