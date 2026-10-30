# Lessons learned

Problems hit while building this homelab: what happened, why, how it was fixed, and what I'd do differently.

> **Fill-in guide:** the **Root cause** and **Fix** lines are facts. Write **What happened** and **Lesson** in your own words; those are the parts you'll explain in interviews. Delete this note when done.

---

## 1. Git repo created in my home directory
**Date:** 2026-10-23
**What happened:** TODO
**Root cause:** Pasted several commands at once. `unzip` failed, but the following lines still ran, so `git init` and `git add .` ran in `~`, staging everything including `~/.ssh` (private key).
**Fix:** Confirmed nothing was pushed (the commit failed: no git identity, `gh` not installed). Removed `~/.git`. Redid it one command at a time with a `pwd` check.
**Lesson:** TODO

## 2. SSH hardening file didn't exist
**Date:** 2026-10-23
**What happened:** TODO
**Root cause:** Assumed a config change had been applied; it hadn't been written.
**Fix:** Created it with `sudo tee`, verified the live config with `sudo sshd -T`.
**Lesson:** TODO

## 3. "No identities found" on chadlab
**Date:** 2026-10-23
**What happened:** TODO
**Root cause:** chadlab never had an SSH key. Password login worked, which hid the gap.
**Fix:** `ssh-keygen -t ed25519`, then `ssh-copy-id` to each Pi.
**Lesson:** TODO

## 4. `sudo cat > file` permission denied
**Date:** 2026-10-23
**What happened:** TODO
**Root cause:** The shell opens the redirect target as my user *before* `sudo` runs.
**Fix:** `... | sudo tee file`.
**Lesson:** TODO

## 5. `sed` didn't change the authorized_keys label
**Date:** 2026-10-23
**What happened:** TODO
**Root cause:** The key was pasted from Windows, so the line ended in a hidden `\r` (CRLF). The `$` anchor didn't match.
**Fix:** Removed the anchor and stripped `\r$`.
**Lesson:** TODO

## 6. `eth0` doesn't exist
**Date:** 2026-10-23
**What happened:** TODO
**Root cause:** Modern Debian uses predictable interface names; ethernet is `end0`.
**Fix:** `ip -br link` / `ip -br addr`.
**Lesson:** TODO

## 7. `lsusb` couldn't find the Pi
**Date:** 2026-10-23
**What happened:** TODO
**Root cause:** `lsusb` only lists USB devices; the Pi was on the network.
**Fix:** Hub device list, `nmap -sn`, `arp -a`.
**Lesson:** TODO

## 8. Two stress tests ran at once
**Date:** 2026-10-23
**What happened:** TODO
**Root cause:** A multi-line paste into tmux split across two shells.
**Fix:** Spotted it from the memory numbers (75% of *available* RAM), kept the real run.
**Lesson:** TODO

## 9. Misread throttling data
**Date:** 2026-10-23
**What happened:** TODO
**Root cause:** Assumed standard RK3399 clocks; this board's OP1 chip runs 2016/1512MHz.
**Fix:** Read the real maximums from `cpuinfo_max_freq`.
**Lesson:** TODO

## 10. Upright placement didn't reduce temperature
**Date:** 2026-10-24
**What happened:** TODO
**Root cause:** The closed case and ambient temperature dominate; orientation barely matters when the heatsink is enclosed.
**Fix:** Accepted light throttling under synthetic load (the real workload is idle); cases kept on for dust; filtered airflow planned.
**Lesson:** TODO

## 11. Boot timestamps were wrong
**Date:** 2026-10-24
**What happened:** TODO
**Root cause:** No RTC battery fitted. The clock resumes from the last shutdown until NTP syncs.
**Fix:** Counted boots instead of trusting start times; RTC battery added to the roadmap.
**Lesson:** TODO

## 12. apt 404 during the unattended-upgrades dry run
**Date:** 2026-10-24
**What happened:** TODO
**Root cause:** Stale package index. The requested security version had been superseded and removed from the mirror.
**Fix:** `sudo apt update`. Revealed 70 pending updates, not the 4 the login banner claimed.
**Lesson:** TODO

## 13. Kernel updates were set to install automatically
**Date:** 2026-10-24
**What happened:** TODO
**Root cause:** Armbian's unattended-upgrades config allows kernel and DTB packages.
**Fix:** Blacklisted kernel/DTB/u-boot/firmware in a drop-in file; did the kernel update by hand, npclab first (canary).
**Lesson:** TODO

## 14. Debian version still said 13.6 after upgrading
**Date:** 2026-10-24
**What happened:** TODO
**Root cause:** Armbian ships its own `base-files` (`26.8.3-13.8+deb13u6`), which outranks Debian's (`13.8+deb13u7`) on version number at equal priority.
**Fix:** None needed. Confirmed with `apt policy` and the dpkg log that the upgrade did run.
**Lesson:** TODO

## 15. Port 53 already in use
**Date:** 2026-10-24
**What happened:** TODO
**Root cause:** `systemd-resolved`'s stub listener on `127.0.0.53:53`.
**Fix:** Disabled the stub with a drop-in; repointed `/etc/resolv.conf` at the real upstream so the Pi doesn't depend on its own Pi-hole.
**Lesson:** TODO

## 16. Pi-hole worked locally but timed out from the laptop
**Date:** 2026-10-24
**What happened:** TODO
**Root cause:** The laptop routed LAN traffic through the Tailscale subnet router; queries arrived from `100.x` and Pi-hole's "local only" mode dropped them.
**Fix:** Diagnosed with `Find-NetRoute` and `pihole -t`; set listening mode `ALL` (safe: no inbound exposure).
**Lesson:** TODO

## 17. Notes said the media stack was "working"
**Date:** 2026-10-24
**What happened:** TODO
**Root cause:** A plan was recorded as if it had been built.
**Fix:** Full audit; corrected the inventory.
**Lesson:** TODO

## 18. Rock Pi rack accessories don't fit
**Date:** 2026-09
**What happened:** TODO
**Root cause:** Mounting holes are 56.03 × 49.01mm vs the Pi 4's 58 × 49mm; side ports differ too.
**Fix:** Checked the official mechanical drawings before buying; shelves or slotted/printed mounts instead.
**Lesson:** TODO

## 19. unattended-upgrades installed but did nothing on chadlab
**Date:** 2026-10-27
**What happened:** Installed `unattended-upgrades` on chadlab (Linux Mint 22.3) and enabled it with `dpkg-reconfigure`. The dry run showed it would only install from `Linuxmint` origins.
**Root cause:** The default `Allowed-Origins` uses `${distro_id}`, which is `Linuxmint` on Mint. Ubuntu's security updates come from origin `Ubuntu` (`noble-security`), so nothing matched and no security updates would ever install, with no error.
**Fix:** Added `"Ubuntu:noble-security"`, `"UbuntuESMApps:noble-apps-security"` and `"UbuntuESM:noble-infra-security"` to `/etc/apt/apt.conf.d/50unattended-upgrades`. Verified with `sudo unattended-upgrade --dry-run --debug`: allowed origins now include `o=Ubuntu,a=noble-security`.
**Lesson:** Installing a tool isn't the same as it working. Verify with a dry run or test. On derivative distros (Mint, Pop!_OS), defaults written for the parent distro can silently not apply.

## 20. Two auto-update systems on chadlab
**Date:** 2026-10-27
**What happened:** Installed unattended-upgrades on chadlab without noticing mintupdate-automation was already enabled (logged 2026-10-24).
**Root cause:** Didn't check the maintenance log before changing the system.
**Fix:** Disabled mintupdate-automation; kept unattended-upgrades (security-only, same as the Pis).
**Lesson:** Read your own docs before changing a system.

## 21. gluetun DNS changes never took effect
**Date:** 2026-10-28
**What happened:** TODO
**Root cause:** Edited the DNS env vars in `compose.yaml`, but the running container was never recreated. `docker inspect` showed only gluetun's defaults (DoT/Cloudflare), and Cloudflare DoT on port 853 kept getting reset over Proton Free.
**Fix:** `docker compose up -d --force-recreate`. Verified with `docker inspect` and the startup log (`Upstream resolver type: doh`). Recreate the whole stack: restarting gluetun alone orphans qBittorrent, which shares its network namespace. Kill switch verified: with gluetun stopped, `wget 1.1.1.1` from qBittorrent → `Network unreachable`.
**Lesson:** TODO

## 22. Backup drill: "0 dashboards" and a bad key paste
**Date:** 2026-10-29
**What happened:** TODO
**Root cause:** Key: copied an incomplete line from the password manager (60 chars vs 74). Dashboards: Grafana 13 stores dashboards in the `resource` table; the legacy `dashboard` table is empty on the live DB too.
**Fix:** Checked length (`wc -c` → 75 incl. newline) and re-entered. Compared backup vs live, then queried `resource`: 1 dashboard present.
**Lesson:** TODO

## 23. Suwayomi hardening: read-only root, UID clash, settings that never applied
**Date:** 2026-10-29
**What happened:** TODO
**Root cause:** (1) The image writes `server-reference.conf` into `startup/`, which also holds the jar, so a tmpfs would hide the server. (2) The image's default UID 1000 is my host user, who is in the docker group (root-equivalent). (3) `KCEF_ENABLED` went into Dockge's `.env` box, which only feeds `${VAR}` substitution, not the container.
**Fix:** (1) Pre-created `server.conf` in a throwaway `--network none` container so the script skips the write. (2) Ran as unused UID 1500. (3) Moved to `environment:`, force-recreated, proved with `docker inspect`. Verified 8 blocked egress/host paths with counters, auth with a real query, and rules surviving a docker restart and reboot.
**Lesson:** TODO

## 24. Isolating Suwayomi: silent failures everywhere
**Date:** 2026-10-30
**What happened:** TODO
**Root cause:** (1) `internal: true` silently drops published ports, including 127.0.0.1. (2) Ports bound to the Tailscale IP failed at boot: Docker started after tailscaled but before the IP existed. (3) DOCKER-USER (FORWARD) never sees container→host-bridge traffic; that's INPUT. (4) Docker tmpfs is `noexec` by default, so zstd's native lib failed under `read_only`. (5) DROP made blocked fetches hang; REJECT fails fast. (6) `tailscale serve` listens on `<ts-ip>%tailscale0`, so same-host clients (Kuma) get connection refused.
**Fix:** (1) `tailscale serve` → pinned container IP, no published ports. (2) Docker drop-in waits ≤60s for the Tailscale IP. (3) `ufw deny from 172.31.60.0/24`. (4) `/tmp` tmpfs with `exec`, `read_only` back on. (5) REJECT rules (later removed with the old 172.30.50 network; `internal: true` + ufw now do the blocking, and the empty pre-Docker unit was deleted). (6) Host-side Kuma push timer. All verified with tests, a Docker restart and two reboots.
**Lesson:** TODO

---

## Interview stories (STAR)

Pick 3–4 and practise them as Situation → Task → Action → Result. Strongest: **#1** (incident handled), **#16** (structured troubleshooting), **#13** (change management / canary), **#2** (verify, don't assume).
