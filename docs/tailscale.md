# Tailscale

WireGuard-based mesh VPN. Remote access with **no open ports**: every device makes outbound connections to Tailscale's coordination server, then connects peer-to-peer.

## Tailnet

| Device | Role | Key expiry |
|---|---|---|
| choppedlab | **Subnet router** for the home LAN | Disabled (always-on infrastructure) |
| iPhone | Client | **Enabled** (can be lost or stolen) |
| Laptop (Windows) | Client | **Enabled** (portable) |
| chadlab | Planned: host-level client (not inside gluetun) | Disabled when added |
| npclab | Planned: backup subnet router | Disabled when added |

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
