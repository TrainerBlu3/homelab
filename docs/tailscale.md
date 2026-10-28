# Tailscale

WireGuard-based mesh VPN. Remote access with **no open ports**: every device makes outbound connections to Tailscale's coordination server, then connects peer-to-peer.

## Tailnet

| Device | Role | Tailnet IP | Key expiry |
|---|---|---|---|
| choppedlab | **Subnet router** for the home LAN, Pi-hole DNS | 100.67.89.105 | Disabled (always-on infrastructure) |
| chadlab | Host-level client (not inside gluetun) | 100.91.58.90 | Disabled (always-on) |
| npclab | Planned: backup subnet router + 2nd Pi-hole | TBD | Disabled when added |
| iPhone | Client | 100.90.120.94 | **Enabled** (can be lost or stolen) |
| Laptop (titorick) | Client | 100.79.135.57 | **Enabled** (portable) |

Account: GitHub login.

## Subnet router (choppedlab)

```bash
curl -fsSL https://tailscale.com/install.sh | sh
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
sudo tailscale up --advertise-routes=192.168.1.0/24
sudo tailscale set --auto-update
```
Admin console → choppedlab → approve the route, disable key expiry.

IP forwarding lets the Pi pass packets between the tailnet and the LAN. Without it, it's only a client.

## Host-level client (chadlab)

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```
No `--accept-routes` (already on the LAN), no `--ssh` (sshd stays in charge). Admin console → disable key expiry.

## MagicDNS names

Connect by name: `<box>.<tailnet>.ts.net` (real tailnet name kept private).
Laptop `~/.ssh/config` and Termius use these names → works at home and away, no dependency on choppedlab.
First connect under a new name shows a fingerprint prompt: if it lists the box's other known addresses, it's the same machine → accept.

## DNS (Pi-hole for all Tailscale devices)

Admin console → DNS → Global nameserver `100.67.89.105` (choppedlab), **Override DNS servers: on**.
Every Tailscale device uses Pi-hole on any network. iPhone: "Use Tailscale DNS settings" on, iCloud Private Relay off.
⚠️ choppedlab down = no DNS while Tailscale is on → turn Tailscale off on the device. Fix later: npclab as 2nd nameserver.
Undo: remove the nameserver.

## Verify

```powershell
tailscale status
tailscale ping choppedlab
```
- `via <LAN IP>:41641` = direct connection.
- `via DERP(<city>)` = relayed through Tailscale's servers (NAT or firewall blocked direct).

Remote test: phone on mobile data, open the hub's admin page.

## Notes

- Windows, macOS and phones accept subnet routes by default. Linux needs `--accept-routes`.
- With routes accepted, the laptop reaches the LAN **through choppedlab even at home**. If choppedlab is down, untick "Use Tailscale subnets" (or add npclab as a backup router).
- Tailscale survived a kernel upgrade and reboot on choppedlab and reconnected by itself.
- Tailscale updates itself (`--auto-update`). Unattended-upgrades only trusts Debian/Armbian sources.
- After installing on Windows, open a **new** terminal (PATH is read at shell start).
- SSH to `192.168.1.x` timing out away from home: laptop Tailscale disconnected (grey in console), or the current network is also `192.168.1.x` (overlapping subnets) → use the tailnet name or IP.
- "unknown node or service" = typo in the tailnet name, or Tailscale off.
- Fallback when a box isn't on Tailscale: `ssh -J trainerred@100.67.89.105 <user>@<lan-ip>`.
