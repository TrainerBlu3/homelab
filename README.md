> **Mantra: security and anonymity.** Nothing exposed publicly, least privilege by default,
> data stays on hardware I control, and third parties see as little as possible.

# homelab

Budget homelab built incrementally: a Lenovo ThinkCentre M80q as the main server and two Radxa Rock Pi 4B+ boards for network services, headed for a 10" mini rack. Built as a hands-on learning project in Linux administration, networking, DNS, security hardening and documentation.

## Machines

Naming theme: **hub device name → hostname → user**.

| Hub name | Hostname | User | Hardware | OS | Role | Status |
|---|---|---|---|---|---|---|
| The Gulag | `chadlab` | `trainerblue` | M80q, i7-10700T, 16GB, 256GB SSD | Linux Mint 22.3 (→ headless later) | Docker host for future services | Key-only SSH, Dockge installed |
| The Trenches | `choppedlab` | `trainerred` | Rock Pi 4B+, RK3399 (OP1), 2GB, eMMC | Armbian 26.8 · Debian 13 Minimal | Tailscale subnet router, Pi-hole (primary) | **Live** |
| The Bunker | `npclab` | `trainergreen` | Rock Pi 4B+, RK3399 (OP1), 2GB, eMMC | Armbian 26.8 · Debian 13 Minimal | Pi-hole (secondary), backup subnet router (planned) | Hardened, awaiting Pi-hole |

All three have DHCP reservations on the Telus hub. IPs are tracked in a private inventory, not this repo.

## Network

```
                    Tailscale tailnet (laptop, phone)
                               │
Internet ── Telus NH20A hub ───┼── The Gulag    (chadlab)
                               ├── The Trenches (choppedlab)  ← subnet router + Pi-hole
                               └── The Bunker   (npclab)
```

- The Telus hub is the gateway and DHCP server. See [network.md](docs/network.md) for its DNS limitations.
- Remote access is **Tailscale only**: outbound connections, no port forwarding, nothing exposed to the internet.
- Planned: Horaco managed 2.5G switch, keepalived floating DNS IP, VLANs, and pfSense later.

## Docs

| Doc | What it covers |
|---|---|
| [Rock Pi setup](docs/rock-pi-setup.md) | Flashing, first boot, IP reservation, naming, users |
| [SSH](docs/ssh.md) | Keys, client config, server hardening |
| [Network](docs/network.md) | Telus hub assessment, DNS design, IPv6 |
| [Pi-hole](docs/pihole.md) | Install, settings, verification, troubleshooting |
| [Tailscale](docs/tailscale.md) | Subnet router, clients, key expiry policy |
| [Maintenance](docs/maintenance.md) | Update policy, routine checks, maintenance log |
| [Stress testing](docs/stress-testing.md) | Board and PSU validation, thermal results |
| [Lessons learned](docs/lessons-learned.md) | Problems hit, root causes, fixes |
| [Roadmap](docs/roadmap.md) | What's done and what's next |

## Configs

- [`configs/sshd/10-hardening.conf`](configs/sshd/10-hardening.conf): server-side SSH lockdown
- [`configs/ssh/config.example`](configs/ssh/config.example): client-side host aliases
- [`configs/apt/51unattended-upgrades-local`](configs/apt/51unattended-upgrades-local): keeps kernel/bootloader out of automatic updates
- [`configs/systemd/10-pihole.conf`](configs/systemd/10-pihole.conf): frees port 53 for Pi-hole
- [`scripts/stress-test.sh`](scripts/stress-test.sh): CPU/RAM stress test with temperature logging
