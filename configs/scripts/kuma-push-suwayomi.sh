#!/bin/sh
# Push Suwayomi health to Uptime Kuma. The host can reach the internal container IP; Kuma can't.
# Checks: serve config points at the container AND the app answers 200.
tailscale serve status 2>/dev/null | grep -q '172.31.60.3:4567' || exit 1
code=$(curl -s -o /dev/null -m 10 -w '%{http_code}' http://172.31.60.3:4567)
[ "$code" = "200" ] || exit 1
curl -s -m 10 "$(cat /etc/kuma-push/suwayomi.url)" >/dev/null
