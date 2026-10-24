# Roadmap

## Done

- [x] Flash both Rock Pis with Armbian Debian 13 Minimal
- [x] Reserve IPs, apply naming theme
- [x] Key-only SSH on both Pis and chadlab (no root, `AllowUsers`)
- [x] Stress test both Pis (two rounds)
- [x] Error baselines saved on both Pis
- [x] Automatic security updates, kernel excluded; first canary kernel rollout
- [x] Tailscale on choppedlab (subnet router), iPhone, laptop
- [x] Telus hub DNS assessment
- [x] Pi-hole on choppedlab, verified locally and from the LAN

## Now

- [ ] Cold boots: 3+ per Pi (before Nov 2)
- [ ] Pi-hole canary: laptop DNS → choppedlab for a day; test the IPv6 leak
- [ ] Horaco switch setup (when it arrives)
- [ ] **Buy UPS** before the house depends on Pi-hole
- [ ] Pi-hole on npclab + nebula-sync
- [ ] keepalived floating DNS IP → hub DNS field
- [ ] Tailscale DNS → Pi-holes
- [ ] Decide on IPv6 (turn off on the hub vs forward)

## Next

- [ ] Tailscale on chadlab (host-level, not inside gluetun)
- [ ] npclab as backup subnet router
- [ ] Unbound recursive DNS on both Pis
- [ ] Health-check script + systemd timer + ntfy
- [ ] Uptime Kuma
- [ ] RTC coin-cell battery for the Pis

## Docker (chadlab): learning path

1. [ ] Uptime Kuma: one container (compose, ports, volumes, restart policies)
2. [ ] Homepage: config files, bind vs named volumes
3. [ ] App + Postgres: networks, `depends_on`, `.env`
4. [ ] qBittorrent behind gluetun: `network_mode: service:`
5. [ ] Full media stack (after storage)

Compose files live in `stacks/` in this repo; real `.env` files stay out of git.

## Hardware (buy order)

1. **UPS:** CyberPower CP850PFCLCD (pure sine). Tower; sits beside the rack. NUT on chadlab for graceful shutdown
2. **Storage:** WD Red Plus 4TB + USB enclosure
3. **Backup drive:** 1–2TB, before anything irreplaceable goes on the server
4. **Rack:** 12U 10", vented shelves, fan unit with dust filter, 10" power strip
5. **Finishing:** short patch cables, velcro, Dual Lock

Later: SFP+ RJ45 module (multi-rate), 2.5G NIC for the M80q, multi-bay DAS, Cisco switch for a CCNA lab.

## Later services

Vaultwarden (after UPS + backups; HTTPS via `tailscale serve`), Immich, Nextcloud, Gitea, pfSense + VLANs, Horaco switch exporter → Prometheus + Grafana, Ansible.

## Not doing

- Raspberry Pis: the RK3399 covers DNS and routing; RAM-driven Pi price hikes make a used 1L mini PC better value if more compute is needed
- Arch on the Pis: no official board support; a rolling release is a poor fit for DNS
- Public exposure of admin interfaces (SSH, Pi-hole, hub, switch): Tailscale only
