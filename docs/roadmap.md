# Roadmap

## Now

- [x] Flash both Rock Pis with Armbian Debian 13 Minimal
- [x] Reserve IPs, apply naming theme
- [x] Key-only SSH on both Pis
- [ ] Stress test both Pis (before Nov 2)
- [x] Key-only SSH on chadlab
- [ ] Tailscale on choppedlab as subnet router
- [ ] Tailscale on chadlab (host-level, not inside gluetun)
- [ ] Pi-hole on choppedlab (primary)
- [ ] Pi-hole on npclab (secondary) + nebula-sync

### Tailscale subnet router (choppedlab)
```bash
curl -fsSL https://tailscale.com/install.sh | sh
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
sudo tailscale up --advertise-routes=192.168.1.0/24
```
Approve the route in the Tailscale admin console.

## Hardware

1. **Switch:** Horaco 8×2.5G + 1×10G SFP+, managed variant
2. **Rack:** 12U 10" (Tecmojo or DeskPi RackMate T2), shelves, 4×80mm fan unit, power strip
3. **UPS:** CyberPower CP850PFCLCD (pure sine). NUT on chadlab for graceful shutdown of all three boxes
4. **Storage:** WD Red Plus 4TB in a USB enclosure, plus a 1–2TB backup drive

Later: multi-bay DAS + mergerfs/SnapRAID, Cisco fanless switch for CCNA lab.

## Software

- Vaultwarden (after UPS; HTTPS via `tailscale serve`)
- Immich, Nextcloud, Gitea
- pfSense on chadlab (router-on-a-stick over VLANs)
- Custom Horaco switch exporter → Prometheus + Grafana
- Headscale (maybe)

## Not doing

- Raspberry Pis: the RK3399 covers DNS and routing, and RAM-driven Pi price hikes make a used 1L mini PC better value if more compute is needed
- Arch on the Pis: no official board support, and a rolling release is a poor fit for DNS
