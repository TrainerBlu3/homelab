# Pi-hole

Network-wide DNS filtering. Primary on **choppedlab**; secondary on **npclab** (planned).

## How it works

Every device asks a DNS server "what's the IP for this name?" before connecting. Pi-hole answers normal lookups by forwarding them to an **upstream** resolver, and answers ad/tracker domains with `0.0.0.0` (IPv4) or `::` (IPv6), so those requests never leave the network.

DNS is critical infrastructure: if it's down, the internet *looks* down to every device. Hence two Pi-holes and a UPS.

## Settings

| Setting | Value | Why |
|---|---|---|
| Interface | `end0` | Wired. Never Wi-Fi for DNS |
| Upstream | Quad9 (filtered, DNSSEC) | Non-profit, no ECS location leak, malware filtering, DNSSEC validation. Unbound planned |
| Blocklist | Default | Well maintained; more lists means more false positives |
| Privacy level | Hide domains and clients | Shared household. Collect the least detail needed |
| Listening mode | **ALL** (permit all origins) | Tailnet clients query from `100.x` addresses. Safe **only** because there's no inbound exposure (see Troubleshooting) |
| Admin page | `http://<choppedlab-ip>/admin` | LAN / Tailscale only |

`/etc/pihole/pihole.toml` is readable only by root/pihole because it holds the password hash. Use `sudo` for `pihole` commands.

## Pre-install: free port 53

`systemd-resolved` runs a stub DNS listener on `127.0.0.53:53`. Disable it with a drop-in ([`configs/systemd/10-pihole.conf`](../configs/systemd/10-pihole.conf)), and repoint the Pi's own resolver at the real upstream:

```bash
sudo ss -tulpn | grep ':53 '                     # what's on port 53
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo cp configs/systemd/10-pihole.conf /etc/systemd/resolved.conf.d/
sudo systemctl restart systemd-resolved
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
```

Verify: `ss` shows nothing on :53, `cat /etc/resolv.conf` shows the hub (not `127.0.0.53`), and `getent hosts deb.debian.org` resolves.

## Install

Read the script before running it as root:
```bash
curl -sSL https://install.pi-hole.net -o pihole-install.sh
less pihole-install.sh
sudo bash pihole-install.sh
sudo pihole setpassword
sudo pihole-FTL --config dns.listeningMode ALL
```

## Verify

On the Pi:
```bash
sudo pihole status
dig @127.0.0.1 google.com +short            # real IPs
dig @127.0.0.1 doubleclick.net +short       # 0.0.0.0
dig @127.0.0.1 doubleclick.net AAAA +short  # ::
```
From another device:
```powershell
nslookup google.com <choppedlab-ip>
nslookup doubleclick.net <choppedlab-ip>
```

## Troubleshooting

**Works on the Pi, times out from the laptop.** The laptop accepts Tailscale subnet routes, so even at home it routed `192.168.1.0/24` through the tunnel. Queries arrived from `100.x` addresses, and the default "local only" listening mode dropped them.
- Diagnose: `Find-NetRoute -RemoteIPAddress <ip>` (Windows) shows the interface used; `sudo pihole -t` shows live queries and their source.
- Fix: listening mode `ALL`.
- Risk: on a host with a public IP this would make an **open resolver** (abused for DDoS amplification). Safe here because nothing inbound reaches port 53.

## Rollout plan

1. One device (laptop) set to Pi-hole by hand for a day.
2. Check the IPv6 leak (see [network.md](network.md)).
3. Secondary Pi-hole on npclab + nebula-sync.
4. keepalived virtual IP → hub DNS field.
5. Tailscale DNS → Pi-holes, "Override local DNS".
6. Unbound as upstream.

### Privacy
- Tuning phase (own devices only): privacy level 0
- House-wide: level 2 (hide domains + clients), 30-day retention
- Household informed before cutover

### Blocklists (2026-10-27)
| List | Purpose | Why this version |
|---|---|---|
| HaGeZi Pro | Ads, trackers, pop-up networks | Balanced level; Pro++ only if needed |
| HaGeZi Gambling (medium) | Gambling sites + ads (Stake etc.) | Medium (~190k) instead of full (~618k) for the 2GB Pi |
| HaGeZi TIF Mini | Malware / phishing / scams | Mini instead of full (2.1M) for RAM and update time |
| HaGeZi DoH | Encrypted DNS servers | Stops browser Secure DNS bypassing Pi-hole without blocking VPNs (Tailscale, gluetun) |
| Perflyst Smart-TV | Smart TV tracking | Tiny; ready for house-wide cutover |

Default list (StevenBlack): disabled, covered by Pro.
Tested with: d3ward adblock test, canyoublockit, dnsleaktest, on.quad9.net.

### Allowlist
| Domain | Reason | Date |
|---|---|---|
| (none yet) | | |
