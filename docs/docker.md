\# Docker (chadlab)



Stacks are managed in \*\*Dockge\*\* (`http://chadlab.<tailnet>.ts.net:5001`), stored in `/opt/stacks/<stack>/`.

Repo copies live in `configs/<stack>/` (synced with `hlstacks`; secrets replaced by `<secret>`).



\## Stacks



| Stack | Image / tag | Port | Purpose |

|---|---|---|---|

| nebula-sync | `ghcr.io/lovelaze/nebula-sync:v0.11.3` (pinned) | – | Hourly Pi-hole sync choppedlab → npclab |

| uptime-kuma | `louislam/uptime-kuma:2` | 3001 | DNS/HTTP monitoring → ntfy Homelab Alerts |

| diun | `crazymax/diun:4` | – | Daily image update check → ntfy updates topic |

| dockge | `louislam/dockge:1` | 5001 | Stack management UI |



\## Tag policy



| Tag style | Use for |

|---|---|

| Exact version (`v0.11.3`) | Pre-1.0 or fast-changing apps. Diun watches newer semver tags via labels |

| Major version (`:2`) | Stable apps: fixes without breaking jumps |

| `latest` | \*\*Never\*\* |



Lesson: `uptime-kuma:1` was end-of-life. Check an image's recommended tags before deploying.



\## Updating a stack



1\. ntfy (updates topic) says a new version is available

2\. Read the release notes

3\. Dockge → stack → change tag (pinned) or click \*\*Update\*\* (major tag) → Deploy

4\. \*\*Prove it\*\* (below)

5\. `hldone`



\## Verify what's actually running



The compose file is what you \*asked for\*; the container is what's \*running\*. Check both.



```bash

docker ps --format "table {{.Names}}\\t{{.Image}}\\t{{.Status}}"   # image + tag of every container

docker logs <name> --tail 30                                      # recent logs

docker logs nebula-sync 2>\&1 | grep -i -E "starting|sync completed"

```



\## Secrets



\- Real values live only in `/opt/stacks/<stack>/.env` on chadlab + the password manager.

\- Repo gets `.env.example` with `<secret>` placeholders (`hlstacks` does this automatically).

\- `.gitignore` covers `.env` and `data/`.



\## Security notes



\- `docker.sock` gives control of Docker (= root on chadlab). Only Diun has it, read-only mount (doesn't limit API calls).

\- Dockge controls Docker too: Tailscale only, never port-forwarded, strong password.



\## Handy commands



| Goal | Command |

|---|---|

| Shell inside a container | `docker exec -it <name> sh` |

| Run one command inside | `docker exec <name> <command>` |

| Reset Dockge password | `docker exec -it dockge npm run reset-password` |

| Test Diun notification | `docker exec diun diun notif test` |

| Disk used by Docker | `docker system df` |

