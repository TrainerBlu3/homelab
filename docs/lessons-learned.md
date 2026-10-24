# Lessons learned

Problems hit while building this homelab: what happened, why, how it was fixed, and what I'd do differently.

> **Fill-in guide:** the **Root cause** and **Fix** lines are facts. Write **What happened** and **Lesson** in your own words; those are the parts you'll explain in interviews. Delete this note when done.

---

## 1. Git repo created in my home directory
**Date:** 2026-10-23
**What happened:**
**Root cause:** Pasted several commands at once. `unzip` failed, but the following lines still ran, so `git init` and `git add .` ran in `~`, staging everything including `~/.ssh` (private key).
**Fix:** Confirmed nothing was pushed (the commit failed: no git identity, `gh` not installed). Removed `~/.git`. Redid it one command at a time with a `pwd` check.
**Lesson:**

## 2. SSH hardening file didn't exist
**Date:** 2026-10-23
**What happened:**
**Root cause:** Assumed a config change had been applied; it hadn't been written.
**Fix:** Created it with `sudo tee`, verified the live config with `sudo sshd -T`.
**Lesson:**

## 3. "No identities found" on chadlab
**Date:** 2026-10-23
**What happened:**
**Root cause:** chadlab never had an SSH key. Password login worked, which hid the gap.
**Fix:** `ssh-keygen -t ed25519`, then `ssh-copy-id` to each Pi.
**Lesson:**

## 4. `sudo cat > file` permission denied
**Date:** 2026-10-23
**What happened:**
**Root cause:** The shell opens the redirect target as my user *before* `sudo` runs.
**Fix:** `... | sudo tee file`.
**Lesson:**

## 5. `sed` didn't change the authorized_keys label
**Date:** 2026-10-23
**What happened:**
**Root cause:** The key was pasted from Windows, so the line ended in a hidden `\r` (CRLF). The `$` anchor didn't match.
**Fix:** Removed the anchor and stripped `\r$`.
**Lesson:**

## 6. `eth0` doesn't exist
**Date:** 2026-10-23
**What happened:**
**Root cause:** Modern Debian uses predictable interface names; ethernet is `end0`.
**Fix:** `ip -br link` / `ip -br addr`.
**Lesson:**

## 7. `lsusb` couldn't find the Pi
**Date:** 2026-10-23
**What happened:**
**Root cause:** `lsusb` only lists USB devices; the Pi was on the network.
**Fix:** Hub device list, `nmap -sn`, `arp -a`.
**Lesson:**

## 8. Two stress tests ran at once
**Date:** 2026-10-23
**What happened:**
**Root cause:** A multi-line paste into tmux split across two shells.
**Fix:** Spotted it from the memory numbers (75% of *available* RAM), kept the real run.
**Lesson:**

## 9. Misread throttling data
**Date:** 2026-10-23
**What happened:**
**Root cause:** Assumed standard RK3399 clocks; this board's OP1 chip runs 2016/1512MHz.
**Fix:** Read the real maximums from `cpuinfo_max_freq`.
**Lesson:**

## 10. Upright placement didn't reduce temperature
**Date:** 2026-10-24
**What happened:**
**Root cause:** The closed case and ambient temperature dominate; orientation barely matters when the heatsink is enclosed.
**Fix:** Accepted light throttling under synthetic load (the real workload is idle); cases kept on for dust; filtered airflow planned.
**Lesson:**

## 11. Boot timestamps were wrong
**Date:** 2026-10-24
**What happened:**
**Root cause:** No RTC battery fitted. The clock resumes from the last shutdown until NTP syncs.
**Fix:** Counted boots instead of trusting start times; RTC battery added to the roadmap.
**Lesson:**

## 12. apt 404 during the unattended-upgrades dry run
**Date:** 2026-10-24
**What happened:**
**Root cause:** Stale package index. The requested security version had been superseded and removed from the mirror.
**Fix:** `sudo apt update`. Revealed 70 pending updates, not the 4 the login banner claimed.
**Lesson:**

## 13. Kernel updates were set to install automatically
**Date:** 2026-10-24
**What happened:**
**Root cause:** Armbian's unattended-upgrades config allows kernel and DTB packages.
**Fix:** Blacklisted kernel/DTB/u-boot/firmware in a drop-in file; did the kernel update by hand, npclab first (canary).
**Lesson:**

## 14. Debian version still said 13.6 after upgrading
**Date:** 2026-10-24
**What happened:**
**Root cause:** Armbian ships its own `base-files` (`26.8.3-13.8+deb13u6`), which outranks Debian's (`13.8+deb13u7`) on version number at equal priority.
**Fix:** None needed. Confirmed with `apt policy` and the dpkg log that the upgrade did run.
**Lesson:**

## 15. Port 53 already in use
**Date:** 2026-10-24
**What happened:**
**Root cause:** `systemd-resolved`'s stub listener on `127.0.0.53:53`.
**Fix:** Disabled the stub with a drop-in; repointed `/etc/resolv.conf` at the real upstream so the Pi doesn't depend on its own Pi-hole.
**Lesson:**

## 16. Pi-hole worked locally but timed out from the laptop
**Date:** 2026-10-24
**What happened:**
**Root cause:** The laptop routed LAN traffic through the Tailscale subnet router; queries arrived from `100.x` and Pi-hole's "local only" mode dropped them.
**Fix:** Diagnosed with `Find-NetRoute` and `pihole -t`; set listening mode `ALL` (safe: no inbound exposure).
**Lesson:**

## 17. Notes said the media stack was "working"
**Date:** 2026-10-24
**What happened:**
**Root cause:** A plan was recorded as if it had been built.
**Fix:** Full audit; corrected the inventory.
**Lesson:**

## 18. Rock Pi rack accessories don't fit
**Date:** 2026-09
**What happened:**
**Root cause:** Mounting holes are 56.03 × 49.01mm vs the Pi 4's 58 × 49mm; side ports differ too.
**Fix:** Checked the official mechanical drawings before buying; shelves or slotted/printed mounts instead.
**Lesson:**

---

## Interview stories (STAR)

Pick 3–4 and practise them as Situation → Task → Action → Result. Strongest: **#1** (incident handled), **#16** (structured troubleshooting), **#13** (change management / canary), **#2** (verify, don't assume).
