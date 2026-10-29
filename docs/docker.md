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
| Run one command