# homelab

Budget homelab built incrementally: a Lenovo ThinkCentre M80q as the main server and two Radxa Rock Pi 4B+ boards for network services, headed for a 10" mini rack.

## Machines

Naming theme: **hub device name → hostname → user**.

| Hub name | Hostname | User | Hardware | OS | Role |
|---|---|---|---|---|---|
| The Gulag | `chadlab` | `trainerblue` | M80q, i7-10700T, 16GB, 256GB SSD | Linux Mint 22.3 (→ headless later) | Docker host: media stack, future services |
| The Trenches | `choppedlab` | `trainerred` | Rock Pi 4B+, RK3399, 2GB, eMMC | Armbian 26.8 · Debian 13 Minimal | Tailscale subnet router, Pi-hole (primary) |
| The Bunker | `npclab` | `trainergreen` | Rock Pi 4B+, RK3399, 2GB, eMMC | Armbian 26.8 · Debian 13 Minimal | Pi-hole (secondary), spare |

All three have DHCP reservations on the Telus hub. IPs are tracked in a private inventory, not this repo.

## Network

```
Internet ── Telus Wi-Fi 6E hub ──┬── The Gulag   (chadlab)
                                 ├── The Trenches (choppedlab)
                                 └── The Bunker   (npclab)
```

- The Telus hub is the gateway and DHCP server. Telus hubs can't disable DHCP, and some block reservations in `.21–.63`.
- Remote access is through **Tailscale**, with outbound connections only and no port forwarding.
- Planned: a managed 2.5G switch (Horaco), VLANs, and later pfSense on the M80q (router-on-a-stick).

## Docs

- [Rock Pi setup](docs/rock-pi-setup.md): flashing, first boot, IP reservation, naming, users
- [SSH](docs/ssh.md): keys, client config, server hardening
- [Stress testing](docs/stress-testing.md): validating boards and power supplies
- [Roadmap](docs/roadmap.md): what's next, hardware and software

## Configs

- [`configs/sshd/10-hardening.conf`](configs/sshd/10-hardening.conf): server-side SSH lockdown
- [`configs/ssh/config.example`](configs/ssh/config.example): client-side host aliases
- [`scripts/stress-test.sh`](scripts/stress-test.sh): CPU/RAM stress test with temperature logging
