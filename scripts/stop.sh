#!/usr/bin/env bash
# stop.sh — Manually stop the dev box.
#
# The VM also auto-stops after 30 minutes of idle (via systemd timer).
# Use this script to stop it immediately.

set -euo pipefail

INSTANCE="zaeem-devbox"
ZONE="us-central1-a"
PROJECT="zaeem-dev"

echo "==> Stopping $INSTANCE..."
gcloud compute instances stop "$INSTANCE" --zone="$ZONE" --project="$PROJECT" --quiet
echo "==> Done. VM is stopped (disk persists, no compute charges until next start)."
