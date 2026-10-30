# Docker (chadlab)

Stacks are managed in **Dockge** (`http://chadlab.<tailnet>.ts.net:5001`), stored in `/opt/stacks/<stack>/`.
Repo copies live in `configs/<stack>/` (synced with `hlstacks`; secrets replaced by `<secret>`).

## Stacks

| Stack | Image / tag | Port | Purpose |
|---|---|---|---|
| nebula-sync | `ghcr.io/lovelaze/nebula-sync:v0.11.3` (pinned) | – | Hourly Pi-hole sync choppedlab → npclab |
| uptime-kuma | `louislam/uptime-kuma:2` | 3001 | DNS/HTTP monitoring → ntfy Homelab Alerts |
| diun | `crazymax/diun:4` | – | Daily image update check → ntfy updates topic |
| dockge | `louislam/dockge:1` | 5001 | Stack management UI |
| monitoring | `prom/prometheus:v3` + `grafana/grafana:13.2.5` (pinned) | 9090, 3000 | Metrics for all 3 boxes (node_exporter), 15-day retention |
| gluetun | qmcgaw/gluetun:v3 | 8000 (TS only) | Proton WireGuard tunnel + kill switch; DoH Quad9, surveillance blocklist |
| qbittorrent | lscr.io/linuxserver/qbittorrent:<pin> | 8080 via gluetun (TS only) | network_mode service:gluetun; bound to tun0; encryption required, anonymous mode |
| suwayomi | v2.4.2366@sha256:1fac27c3… | 4567 (TS only) | Isolated: see Suwayomi section |

## Tag policy

| Tag style | Use for |
|---|---|
| Exact version (`v0.11.3`) | Pre-1.0 or fast-changing apps. Diun watches newer semver tags via labels |
| Major version (`:2`) | Stable apps: fixes without breaking jumps |
| `latest` | **Never** |

Lesson: `uptime-kuma:1` was end-of-life. Check an image's recommended tags before deploying.

## Adding a new service

1. **Decide:** image + tag, port (check the port list), data folders, secrets, what it needs to reach
2. **Do it:** Dockge → new stack → compose (major/exact tag, `restart: unless-stopped`, `./data` volume, `.env` for secrets) → Deploy
3. **Prove it:** `docker ps` (right tag, running) + `docker logs <name> --tail 30` + use it over Tailscale
4. **Write it:** Uptime Kuma monitor, password manager entry (URL with port), row in the Stacks table + port list, `hldone`

## Updating a stack

1. ntfy (updates topic) says a new version is available
2. Read the release notes
3. Dockge → stack → change tag (pinned) or click **Update** (major tag) → Deploy
4. **Prove it** (below)
5. `hldone`

## Verify what's actually running

The compose file is what you *asked for*; the container is what's *running*. Check both.

```bash
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"   # image + tag of every container
docker logs <name> --tail 30                                     # recent logs
docker logs nebula-sync 2>&1 | grep -i -E "starting|sync completed"
```

## Secrets

- Real values live only in `/opt/stacks/<stack>/.env` on chadlab + the password manager.
- Repo gets `.env.example` with `<secret>` placeholders (`hlstacks` does this automatically).
- `.gitignore` covers `.env` and `data/`.

## Security notes

- `docker.sock` gives control of Docker (= root on chadlab). Only Diun has it, read-only mount (doesn't limit API calls).
- Dockge controls Docker too: Tailscale only, never port-forwarded, strong password.
- Future: zero-trust hardening (Tailscale-only ports, `cap_drop`/`no-new-privileges`, socket proxy for Diun, internal DB networks, egress rules).

## Handy commands

| Goal | Command |
|---|---|
| Shell inside a container | `docker exec -it <name> sh` |
| Run one command inside | `docker exec <name> <command>` |
| Reset Dockge password | `docker exec -it dockge-dockge-1 npm run reset-password` |
| Test Diun notification | `docker exec diun diun notif test` |
| Disk used by Docker | `docker system df` |

## Baseline before monitoring (2026-10-28)

| Box | RAM used / total | Disk used | Load (1/5/15) | Temp | Containers / services |
|---|---|---|---|---|---|
| chadlab | 1.1G / 15G (14G avail) | 18G / 234G (8%) | 0.02 0.05 0.01 | – | dockge, nebula-sync, uptime-kuma, diun |
| choppedlab | 290M / 1.9G (1.6G avail) | 2.2G / 29G (8%) | 0.23 0.12 0.03 | 36.9°C | Pi-hole (primary), Tailscale subnet router |
| npclab | 280M / 1.9G (1.7G avail) | 2.2G / 29G (8%) | 0.06 0.03 0.00 | 37.5°C | Pi-hole (replica), Tailscale subnet router |


## Suwayomi (isolated)

| Control | Setting |
|---|---|
| Image | `v2.4.2366@sha256:1fac27c387dc2ea9949e1a01ad7f6d6de9d72d3988338a95476748e5c45c4582` |
| User | UID 1500 (image default 1000 = my host user, docker group = root-equivalent) |
| Filesystem | `read_only: true`; tmpfs `/tmp:size=256m,mode=1777,exec` (native libs like zstd need exec — Docker tmpfs is noexec by default); `server.conf` pre-created so the startup script never writes to `startup/` (holds the world-writable jar) |
| Privileges | `cap_drop: ALL`, `no-new-privileges`, `pids_limit: 256`, 1g RAM, 2 CPU, logs 3×10MB |
| Network | External `app-internal` (172.31.60.0/24, internal, no route out), pinned IP 172.31.60.3, **no published ports** |
| Inbound | `tailscale serve` → 172.31.60.3:4567 (HTTPS on chadlab's ts.net name, tailnet only, funnel off) |
| Egress | Only via Squid (`egress-proxy`), ACL scoped to 172.31.60.3/32 |
| Host access | ufw `deny from 172.31.60.0/24` (container→host bridge IP = INPUT chain, not DOCKER-USER) |
| Auth | `ui_login`, password via `AUTH_PASSWORD_FILE` (`secrets/` 700 root, file 400 UID 1500). Note: written plaintext into `data/server.conf` → `data/` is 700 |
| Sources | MangaPlus (official Shueisha, free tier) + local. KCEF off, FlareSolverr off, bundled UI, no UI updates |
| Updates | Diun `watch_repo=true` + `include_tags=^v\d+\.\d+\.\d+$` (a tag+digest pin never "updates" by itself; Diun has to list newer tags) |

**Exception (2026-10-30):** the MangaPlus extension runs on this host, not in a separate VM (deliberate exception to the containment rule). Squid allowlist kept as configured.

**Verified 2026-10-30:** host via bridge blocked, direct internet blocked, read-only root (`startup/` write fails), UI 200; survives docker restart + reboot.

**Monitoring:** Kuma **push** monitor. `kuma-push-suwayomi.timer` (60s) checks `tailscale serve` config + `http://172.31.60.3:4567` → 200, then pushes. Kuma can't reach the serve URL: `serve` listens on `<ts-ip>%tailscale0` (interface-bound), so same-host clients get connection refused.

**Auth test:** `{ mangas { totalCount } }` without token → `Unauthorized`. HTTP 200 alone proves nothing (GraphQL returns errors in the body).

**Known:** GraphQL errors include Java stack traces (info disclosure; tailnet-only).

**Settings rule:** settings in `environment:`, secrets in `secrets/`, Dockge `.env` box stays empty.

**Upgrade:** new tag + digest → compare `server-reference.conf` vs `data/server.conf` on major versions → re-run isolation, auth and read-only tests.

## Squid egress proxy

| Control | Setting |
|---|---|
| Image | `ubuntu/squid@ubuntu/squid@sha256:6a097f68bae708cedbabd6188d68c7e2e7a38cedd05a176e1cc0ba29e3bbe029` (Squid 6.x, Ubuntu 24.04 base) |
| User | UID 1502 from the start (`entrypoint: squid -N`) — no root, no privilege drop |
| Filesystem | `read_only: true`; tmpfs `/run`, `/var/spool/squid`, `/var/log/squid` (owned 1502), `/tmp` |
| Privileges | `cap_drop: ALL`, `no-new-privileges`, 256m RAM, `pids_limit: 64` |
| Networks | `app-internal` (clients) + `squid-egress` (outbound) — both external |
| Clients | `acl app_net src 172.31.60.3/32` — Suwayomi only |
| Rules | CONNECT 443 to allowlisted domains only; `deny all` last; cache off |
| Logging | `access_log stdio:/dev/stdout squid`, `cache_log stdio:/dev/stderr` → `docker logs egress-proxy` |
| Disabled | `pinger_enable off` (needs NET_RAW; not needed for a single proxy) |
| Diun | `watch_repo=true`, `include_tags=^\d+\.\d+.*-24\.04.*$` |

**Tests:** allowed domain → `connect=200`; other domain → `connect=403` (use `%{http_connect}` — `%{http_code}` shows 000 for refused tunnels); no proxy → timeout; other IP on the subnet → 403; `TCP_DENIED` in logs.

**Config changes:** edit `squid.conf` → `docker restart egress-proxy` (`squid -k reconfigure` didn't always reload ACLs) → re-run tests.

**Weekly review:** `docker logs egress-proxy --since 7d 2>&1 | grep TCP_DENIED | awk '{print $7}' | sort | uniq -c | sort -rn`

## Shared networks

Owned by no stack; stacks join them as `external: true`. Created by `/opt/scripts/networks/` (idempotent: creates if missing, verifies if present, exit 1 if settings differ).

| Network | Subnet | Internal | Members |
|---|---|---|---|
| `app-internal` | 172.31.60.0/24 | yes (no route out) | suwayomi (.3), egress-proxy |
| `squid-egress` | 172.31.61.0/24 | no | egress-proxy |
| `monitoring` | 172.31.62.0/24 | no | prometheus, grafana (owned by the monitoring stack, not the script) |

**Rebuild order (chadlab):** network script → `squid` → `suwayomi`.

**Gotcha:** `internal: true` silently drops published ports (including 127.0.0.1). Reach internal containers via `tailscale serve` → pinned container IP.

## Host firewall and boot order

| Piece | What |
|---|---|
| `docker-iptables-pre.service` | Runs `/opt/scripts/docker-iptables-pre.sh`; `Before=` + `RequiredBy=docker.service` → Docker won't start without it. Test script by hand after any edit (`echo $?` = 0) |
| ufw `deny from 172.31.60.0/24` | Container → host bridge IP goes through INPUT, not DOCKER-USER (FORWARD) |
| `docker.service.d/10-wait-tailscale.conf` | Docker waits ≤60s for the Tailscale IP before starting. `After=tailscaled` alone isn't enough (daemon started ≠ IP assigned). Fixes the boot race that stopped gluetun |
| `kuma-push-suwayomi.timer` | Host-side health push for Suwayomi every 60s (Kuma can't reach `serve` URLs from the same host) |

**UIDs:** 1500 Suwayomi · 1501 Caddy (planned) · 1502 Squid — all unused on the host.

**Rollback:** `tailscale serve reset` → `compose down` suwayomi + squid → `docker network rm app-internal squid-egress` → remove `10-wait-tailscale.conf` → `systemctl disable --now kuma-push-suwayomi.timer`.


