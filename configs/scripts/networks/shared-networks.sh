#!/bin/sh
# Shared Docker networks for app stacks. Owned by NO stack; stacks join them as `external: true`.
# Create before deploying squid / suwayomi / aggregator.
# Idempotent: creates missing networks; verifies existing ones; exits 1 if any differ.
set -e
FAIL=0

ensure_net() {
  name=$1 subnet=$2 internal=$3
  if docker network inspect "$name" >/dev/null 2>&1; then
    int=$(docker network inspect "$name" --format '{{.Internal}}')
    sub=$(docker network inspect "$name" --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}')
    if [ "$int" = "$internal" ] && [ "$sub" = "$subnet" ]; then
      echo "OK      $name ($subnet, internal=$internal)"
    else
      echo "DIFFERS $name: internal=$int subnet=$sub (want $internal, $subnet)" >&2
      FAIL=1
    fi
  else
    if [ "$internal" = "true" ]; then
      docker network create --driver bridge --internal --subnet "$subnet" "$name" >/dev/null
    else
      docker network create --driver bridge --subnet "$subnet" "$name" >/dev/null
    fi
    echo "CREATED $name ($subnet, internal=$internal)"
  fi
}

ensure_net app-internal  172.31.60.0/24 true
ensure_net squid-egress  172.31.61.0/24 false

exit $FAIL
