# Uptime Kuma monitors

Notification: **Homelab Alerts** (ntfy, priority 4, topic in password manager). Default on all monitors.
Database: SQLite (in `./data`, not committed).

| Name | Type | Target | Interval | Retries |
|---|---|---|---|---|
| choppedlab DNS | DNS | `example.com` via resolver `192.168.1.176:53` | 60s | 2 |
| npclab DNS | DNS | `example.com` via resolver `192.168.1.178:53` | 60s | 2 |
| choppedlab Pi-hole UI | HTTP(s) | `http://192.168.1.176/admin/` | 60s | 2 |
| npclab Pi-hole UI | HTTP(s) | `http://192.168.1.178/admin/` | 60s | 2 |
| gluetun VPN | HTTP(s) – Keyword `running` | `http://<chadlab-ts>:8000/v1/vpn/status` | 60s | 2 |
| qBittorrent UI | HTTP(s) | `http://<chadlab-ts>:8080` | 60s | 2 |
| Prometheus | HTTP(s) | `http://<chadlab-ts>:9090/-/healthy` | 60s | 2 |
| Grafana | HTTP(s) | `http://<chadlab-ts>:3000/api/health` | 60s | 2 |

## Notes

- **gluetun** uses a keyword monitor because the API returns 200 even when the tunnel is down; only `running` in the body means it's up.
- **qBittorrent red, gluetun green** = qBittorrent orphaned after a gluetun restart → `docker compose up -d --force-recreate` in `/opt/stacks/gluetun`.
- **Both red** = gluetun or the tunnel is down; check `docker logs gluetun`.
- No "Docker Container" monitors: they need the Docker socket mounted into Kuma (root-equivalent).