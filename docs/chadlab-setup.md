\## chadlab — automatic security updates



\- Package: `unattended-upgrades` (installed 2026-10-27)

\- Schedule: `/etc/apt/apt.conf.d/20auto-upgrades` → both values `"1"` (daily)

\- \*\*Mint gotcha:\*\* default `Allowed-Origins` uses `${distro\_id}` = `Linuxmint`, which

&#x20; doesn't match Ubuntu's security repo, so nothing gets installed. Added to

&#x20; `/etc/apt/apt.conf.d/50unattended-upgrades`:

&#x20; ```

&#x20; "Ubuntu:noble-security";

&#x20; "UbuntuESMApps:noble-apps-security";

&#x20; "UbuntuESM:noble-infra-security";

&#x20; ```

\- Verify: `sudo unattended-upgrade --dry-run --debug 2>\&1 | grep -i "allowed origins"`

&#x20; → must include `o=Ubuntu,a=noble-security`

\- Log: `/var/log/unattended-upgrades/unattended-upgrades.log`

\- Reboots: not automatic. Check with `cat /var/run/reboot-required`



\## chadlab — boot target



\- Switched to text console: `sudo systemctl set-default multi-user.target`

\- Undo: `sudo systemctl set-default graphical.target`

