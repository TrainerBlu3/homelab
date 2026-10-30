#!/bin/bash
set -euo pipefail

if [[ "${1:-}" == "cleanup" ]]; then
    exit 0
fi

# Block container→host-bridge-IP (prevents reaching host services)

# Block container→LAN (if you want it)
# sudo iptables -C DOCKER-USER -s 172.31.60.0/24 -d 192.168.0.0/16 -j REJECT 2>/dev/null || \
#     sudo iptables -I DOCKER-USER -s 172.31.60.0/24 -d 192.168.0.0/16 -j REJECT   
