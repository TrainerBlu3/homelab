# Roadmap

## Done

- [x] Flash both Rock Pis with Armbian Debian 13 Minimal
- [x] Reserve IPs, apply naming theme
- [x] Key-only SSH on both Pis and chadlab (no root, `AllowUsers`)
- [x] Stress test both Pis (two rounds)
- [x] Error baselines saved on both Pis
- [x] Automatic security updates, kernel excluded; first canary kernel rollout
- [x] unattended-upgrades on chadlab (Ubuntu origins fix); mintupdate-automation disabled
- [x] Tailscale on choppedlab, npclab, chadlab, iPhone, laptop
- [x] Subnet router HA (choppedlab + npclab), failover tested
- [x] Telus hub DNS assessment
- [x] Pi-hole on choppedlab + npclab, nebula-sync (full sync)
- [x] Tailscale DNS → both Pi-holes, failover tested
- [x] ntfy push + weekly update-check timer on chadlab
- [x] Docker + Dockge on chadlab, Diun for image updates
- [x] Uptime Kuma v2
- [x] Prometheus + Grafana, node_exporter on all 3 boxes (dashboard 1860 + temps)
- [x] gluetun (Proton Free, WireGuard, DoH Quad9) + qBittorrent, kill switch verified

## Now

- [ ] Pi-hole soak: own devices only, ~1 month before house-wide cutover
- [ ] Cold boots: 3+ per Pi
- [ ] Horaco switch setup (when it arrives)
- [ ] **Buy UPS** before the house depends on Pi-hole
- [ ] Decide on IPv6 (turn off on the hub vs forward)

## Next

- [ ] Kavita (DRM-free / public-domain library)
- [ ] archive.org pipeline: `ia` CLI + systemd timer → Kavita / Paperless
- [ ] Pi-hole Teleporter backups off-box
- [ ] keepalived floating DNS IP → hub DNS field
- [ ] House-wide DNS cutover (privacy level 2, tell the household)
- [ ] Grafana alerts → ntfy
- [ ] Unbound recursive DNS on both Pis
- [ ] RTC coin-cell battery for the Pis

## Black Friday (Nov 2026)

- [ ] Proton VPN Plus (2-yr, target ≤ ~$90 CAD)
- [ ] New WireGuard key (NAT-PMP **on**) → update gluetun `.env`, remove `FREE_ONLY`
- [ ] gluetun: `SERVER_COUNTRIES`, `VPN_PORT_FORWARDING=on`, `PORT_FORWARD_ONLY=on`
- [ ] qBittorrent listen port = forwarded port; test with a Linux ISO

## Hardening batch (with Dockge)

- [ ] Dockge: Tailscale-only bind, `no-new-privileges`, `cap_drop`
- [ ] gluetun control server auth: config.toml role → `GET /v1/vpn/status` only, API key; X-API-Key header in Kuma
- [ ] Flip "all interfaces" ports in network.md to Tailscale only, one service at a time
- [ ] Docker socket proxy for Diun; internal-only networks for databases

## Docker (chadlab): learning path

1. [x] Uptime Kuma: one container (compose, ports, volumes, restart policies)
2. [ ] Homepage: config files, bind vs named volumes
3. [ ] App + Postgres: networks, `depends_on`, `.env`
4. [x] qBittorrent behind gluetun: `network_mode: service:`
5. [ ] Jellyfin for own media (after storage)

Compose files are copied to `configs/<stack>/` by `hlstacks`; real `.env` files stay out of git (`.env.example` only).

## Hardware (buy order)

1. **UPS:** CyberPower CP850PFCLCD (pure sine). Tower; sits beside the rack. NUT on chadlab for graceful shutdown
2. **Storage:** WD Red Plus 4TB + USB enclosure
3. **Backup drive:** 1–2TB, before anything irreplaceable goes on the server
4. **Rack:** 12U 10", vented shelves, fan unit with dust filter, 10" power strip
5. **Finishing:** short patch cables, velcro, Dual Lock

Later: SFP+ RJ45 module (multi-rate), 2.5G NIC for the M80q, multi-bay DAS, Cisco switch for a CCNA lab.

## Later services

Vaultwarden (after UPS + backups; HTTPS via `tailscale serve`), Immich, Nextcloud, Gitea, Homepage, pfSense + VLANs, Horaco switch exporter → Prometheus + Grafana, Ansible.

## Not doing

- Raspberry Pis: the RK3399 covers DNS and routing; RAM-driven Pi price hikes make a used 1L mini PC better value if more compute is needed
- Arch on the Pis: no official board support; a rolling release is a poor fit for DNS
- Public exposure of admin