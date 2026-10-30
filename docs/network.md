# Network

## Layout

| Device | Connection | Addressing |
|---|---|---|
| Telus NH20A hub | Gateway, DHCP server, Wi-Fi | `192.168.1.254` |
| chadlab, choppedlab, npclab | Wired to the hub (switch planned) | DHCP reservations |
| Laptop, phone | Wi-Fi / mobile, plus Tailscale | DHCP / tailnet `100.x` |

Infrastructure is always **wired** and reserved by the **ethernet** MAC (`end0`), never Wi-Fi.

## Telus hub assessment (pre-deployment)

Checked before installing Pi-hole, so the DNS design fits the hardware.

| Setting | Finding | Impact |
|---|---|---|
| LAN DHCP pool | `.64–.253`, lease 1 day; `.21–.63` blocked for reservations | Reservations go inside the pool |
| LAN DHCP DNS | **Single** "DNS Server" field, no secondary. Empty = hub hands out itself | Can't hand out two Pi-holes → need a floating virtual IP for redundancy |
| IPv6 LAN | No DNS field. Hub advertises **itself** as IPv6 DNS (RDNSS) | Devices preferring IPv6 can bypass Pi-hole (**DNS leak**) |
| IPv6 WAN DNS 1/2 | Empty = learned from Telus; editable | Option: hub forwards to Pi-hole |
| DHCP disable | Unconfirmed; Telus forum reports conflict | Pi-hole DHCP is a last resort |

Devices on this network actively use IPv6 (Tailscale picks IPv6 for direct LAN connections), so the leak is a real risk, not a theoretical one.

## DNS design

**Goal:** every device uses Pi-hole; DNS survives one Pi failing.

1. **Now:** Pi-hole on choppedlab, tested with one device at a time (canary).
2. **Redundancy:** Pi-hole on npclab, synced with nebula-sync. **keepalived (VRRP)** shares one virtual IP between the two Pis. The hub's single DNS field points at that virtual IP; if choppedlab dies, npclab takes over the IP within seconds.
3. **IPv6 leak:** test after rollout. Options:
   - turn off IPv6 on the hub (simplest, closes the leak), or
   - set the hub's WAN DNS to the Pi-holes (keeps IPv6, loses per-device stats), or
   - set DNS per device.
4. **Remote:** Tailscale DNS points tailnet devices at the Pi-holes, so ad-blocking works away from home.
5. **Prerequisite:** UPS before the whole house depends on Pi-hole.

## Principles

- **Infrastructure doesn't depend on itself.** The Pis resolve their own lookups through the hub, not their own Pi-hole, so a broken Pi-hole can't stop the Pi from updating or syncing its clock.
- **Never take both halves of a redundant pair down at once.** Stagger reboots and updates.

## IPv6 leak: confirmed and closed (2026-10-24)
- With IPv4 DNS set to Pi-hole, `nslookup doubleclick.net` was answered by Telus's IPv6 resolver and returned real addresses: the hub advertises Telus's IPv6 DNS directly.
- Fix: IPv6 was disabled on the hub. Rollback: re-enable per the screenshot in photos/ (local only).

## Ports (chadlab)

| Port | Service | Bind |
|---|---|---|
| 3000 | Grafana | all interfaces |
| 3001 | Uptime Kuma | all interfaces |
| 5001 | Dockge | all interfaces |
| 9090 | Prometheus | all interfaces |
| 9100 | node_exporter (all 3 boxes) | all interfaces (host) |
| 8000 | gluetun status API | Tailscale only |
| 8080 | qBittorrent WebUI (through gluetun) | Tailscale only |
| 5000 | Kavita (planned) | — |
| 4567 | Suwayomi | Tailscale only |
