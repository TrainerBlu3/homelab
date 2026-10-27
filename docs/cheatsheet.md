# Homelab Cheat Sheet

Quick reference for the daily workflow: docs, git, SSH, Tailscale, and checks.
**Where to run it** matters, so every section says which machine.

> Read your prompt first:
> `PS C:\Users\Milton>` = **laptop (PowerShell)** · `trainerblue@chadlab` / `trainerred@choppedlab` / `trainergreen@npclab` = **that server (bash)**

---

## 1. Profile shortcuts (laptop, PowerShell)

These live in `$PROFILE` (`C:\Users\Milton\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`).

| Command | What it does | Example |
|---|---|---|
| `hl` | Jump to the repo folder | `hl` |
| `hldoc <name>` | Open `docs/<name>.md` in Notepad (creates it if new) | `hldoc pihole` |
| `hllog <box> <task> <notes>` | Add a dated row to the log table at the **end** of `maintenance.md` | `hllog npclab "pihole" "Installed v6"` |
| `hlstatus` | Show what changed + last 5 commits | `hlstatus` |
| `hlpull` | Get the latest from GitHub | `hlpull` |
| `hlpush <msg>` | Add docs, commit, push in one go | `hlpush "pihole: npclab install"` |

**Rules**
- `hllog` always appends to the **end** of `maintenance.md` → keep long notes in other docs (`chadlab-setup.md`, etc.), only log rows go there.
- Save in Notepad (**Ctrl+S**) **before** `hlpush`, or git commits the old version.
- After editing `$PROFILE`, reload it: `. $PROFILE`

---

## 2. Git workflow (laptop)

The normal loop after any homelab change:

```powershell
hlpull                                  # 1. start fresh
hllog <box> "<task>" "<notes>"          # 2. log it
hldoc <doc>                             # 3. write details, Ctrl+S, close
hlstatus                                # 4. check what changed
hlpush "<box>: <what you did>"          # 5. commit + push
```

Manual version (what `hlpush` does underneath):

```powershell
git status                 # what changed (red = not staged, green = staged)
git diff docs/<file>.md    # exact changes (press q to quit)
git add docs/              # stage everything in docs/
git commit -m "message"    # save a snapshot locally
git push                   # upload to GitHub
```

| Term | Meaning |
|---|---|
| **modified** | File existed and changed |
| **untracked** | New file git hasn't seen yet |
| **staged** | Marked to be included in the next commit (`git add`) |
| **commit** | A saved snapshot with a message |
| **push / pull** | Upload to / download from GitHub |

**Commit message habit:** `<box or area>: <what changed>`, one change per commit.
e.g. `chadlab: unattended upgrades`, `lessons-learned: fill in 1-18`

**Find unfinished notes:** `git grep -n TODO docs/`

---

## 3. SSH (laptop → servers)

| Goal | Command |
|---|---|
| At home, by name | `ssh choppedlab` · `ssh npclab` · `ssh chadlab` |
| Away, via Tailscale | `ssh trainerred@100.67.89.105` (choppedlab) |
| Away, box **without** Tailscale (jump through choppedlab) | `ssh -J trainerred@100.67.89.105 trainerblue@192.168.1.167` |
| Run one command without logging in | `ssh choppedlab "uptime"` |
| Leave a server | `exit` |

**How `-J` works:** laptop → (passes through choppedlab) → destination. Your **laptop's** key is used for both hops; choppedlab never sees your session.

**Shortcuts** go in `C:\Users\Milton\.ssh\config`:

```
Host choppedlab-ts
    HostName 100.67.89.105
    User trainerred

Host chadlab-remote
    HostName 192.168.1.167
    User trainerblue
    ProxyJump choppedlab-ts
```

Then: `ssh chadlab-remote` works from anywhere.

**Fingerprint prompt** ("authenticity of host can't be established") = first connection to that name/IP. Check it, then `yes`:

```powershell
ssh-keygen -l -F <host-or-ip>        # what the laptop already has stored
```
⚠️ **"REMOTE HOST IDENTIFICATION HAS CHANGED"** = stop and find out why (reinstall? wrong IP?). Remove a known-stale entry with `ssh-keygen -R <host>`.

---

## 4. SSH keys (on each server)

| Goal | Command (on the server) |
|---|---|
| List key names | `awk '{print $NF}' ~/.ssh/authorized_keys` |
| Count keys | `wc -l ~/.ssh/authorized_keys` |
| Backup before editing | `cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.bak` |
| Edit / rename | `nano ~/.ssh/authorized_keys` (only change the **last word**) |
| Add a key | `echo 'ssh-ed25519 AAAA... name-2026-10' >> ~/.ssh/authorized_keys` |
| Remove exact duplicates | `awk '!seen[$0]++' ~/.ssh/authorized_keys > /tmp/ak && cat /tmp/ak > ~/.ssh/authorized_keys && rm /tmp/ak` |
| Restore backup | `cp ~/.ssh/authorized_keys.bak ~/.ssh/authorized_keys` |

**Rules**
- `>>` = append ✅ · `>` = overwrite ❌ (would lock you out)
- Keep the current session open and **test login from a second window** before closing.
- Key naming: `<device>-<what>-<yyyy-mm>` → `titorick-laptop-2026-10`
- Lost device → delete its line on **every** box.

| Box | Keys |
|---|---|
| choppedlab | titorick-laptop, chadlab-trainerblue, iphone14-termius |
| npclab | titorick-laptop, chadlab-trainerblue, iphone14-termius |
| chadlab | titorick-laptop, iphone14-termius |

---

## 5. nano (on servers)

| Keys | Action |
|---|---|
| **Ctrl+O**, Enter | Save |
| **Ctrl+X** | Exit (asks Y/N if unsaved) |
| **Ctrl+K** | Cut current line (delete a line) |
| **Ctrl+U** | Paste cut line |
| **Ctrl+W** | Search |
| **Ctrl+C** | Cancel a prompt (chimes if nothing to cancel, which is normal) |

Bell sound off: Windows Terminal → Settings → profile → Advanced → Bell notification style → untick **Audible**.
No nano on Windows → use `notepad <file>` or `code <file>`.

---

## 6. Tailscale

| Goal | Where | Command |
|---|---|---|
| Status / who's online | laptop or server | `tailscale status` |
| Test reachability | laptop | `tailscale ping choppedlab` |
| Connect laptop (use subnet routes) | laptop | `tailscale up --accept-routes` (or tray → Connect, Settings → Use Tailscale subnets) |
| Install on a server | server | `curl -fsSL https://tailscale.com/install.sh \| sh` then `sudo tailscale up` |
| Get a box's tailnet IP | server | `tailscale ip -4` |

**Server rules:** disable key expiry in the admin console · no `--accept-routes` on boxes already on the LAN · no `--ssh` (sshd stays in charge).
**If SSH to a `192.168.1.x` address times out away from home:** laptop Tailscale disconnected (grey in console) **or** the network you're on is also `192.168.1.x` → use the `100.x` address or `-J`.

---

## 7. Health checks (on servers)

| Check | Command |
|---|---|
| Live dashboard | `btop` |
| Uptime + load average | `uptime` |
| Disk space | `df -h` |
| Memory | `free -h` |
| Which machine am I on? | `hostname` |
| Pi-hole status | `pihole status` |
| Is a reboot needed? | `cat /var/run/reboot-required 2>/dev/null \|\| echo "no reboot needed"` |
| Security updates working? (chadlab) | `sudo unattended-upgrade --dry-run --debug 2>&1 \| grep -i "allowed origins"` |
| Update log | `less /var/log/unattended-upgrades/unattended-upgrades.log` |
| Recent errors | `journalctl -p err -b` |
| Previous boot's last lines | `journalctl -b -1 -e` |
| Safe shutdown | `sudo poweroff` |
| Reboot | `sudo reboot` |

**Load average** = processes running or waiting, over 1 / 5 / 15 min. Compare to thread count (chadlab 16, Pis 6): 0.1 = idle, 16 on chadlab = fully busy.

---

## 8. Dependency map (what breaks if a box goes down)

| Box down | Effect |
|---|---|
| **choppedlab** | Pi-hole DNS stops (devices using it lose name lookups) · subnet route / remote access to LAN IPs stops |
| **npclab** | Nothing yet (will be 2nd Pi-hole / HA) |
| **chadlab** | Nothing critical yet (Dockge only) |

Update this table every time a new service goes live.
