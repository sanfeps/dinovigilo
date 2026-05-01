#!/usr/bin/env bash
# Sync this repo's pb_hooks/ and pb_migrations/ to the PocketBase host and
# restart the service. Idempotent — safe to re-run.
#
# Usage:  ./deploy.sh <ssh-host>          # e.g. ./deploy.sh openclaw-lab
# Assumes the host has /opt/pocketbase already installed and a systemd unit
# named "pocketbase". See README.md for first-time setup.

set -euo pipefail

HOST="${1:?Usage: $0 <ssh-host>}"
REMOTE_BASE="/opt/pocketbase"

cd "$(dirname "$0")"

echo "→ Syncing pb_hooks/ to $HOST:$REMOTE_BASE/pb_hooks/"
rsync -av --delete pb_hooks/ "$HOST:$REMOTE_BASE/pb_hooks/"

echo "→ Syncing pb_migrations/ to $HOST:$REMOTE_BASE/pb_migrations/"
rsync -av --delete pb_migrations/ "$HOST:$REMOTE_BASE/pb_migrations/"

echo "→ Restarting pocketbase.service"
ssh "$HOST" 'sudo systemctl restart pocketbase && sleep 1 && systemctl is-active pocketbase'

echo "✓ Deployed."
