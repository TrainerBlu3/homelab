\# Uptime Kuma monitors



Notification: \*\*Homelab Alerts\*\* (ntfy, priority 4, topic in password manager). Default on all monitors.

Database: SQLite (in `./data`, not committed).



| Name | Type | Target | Interval | Retries |

|---|---|---|---|---|

| choppedlab DNS | DNS | `example.com` via resolver `192.168.1.176:53` | 60s | 2 |

| npclab DNS | DNS | `example.com` via resolver `192.168.1.178:53` | 60s | 2 |

| choppedlab Pi-hole UI | HTTP(s) | `http://192.168.1.176/admin/` | 60s | 2 |

| npclab Pi-hole UI | HTTP(s) | `http://192.168.1.178/admin/` | 60s | 2 |

