#!/usr/bin/env bash
# clone-repos.sh — Clone repos into ~/workspace/.
#
# Requires SSH agent forwarding (run after SSHing in via start.sh).
# Safe to re-run — skips repos that already exist.

set -euo pipefail

WORKSPACE="$HOME/workspace"
mkdir -p "$WORKSPACE"

REPOS=(
  travel_agent
)

echo "==> Cloning repos into $WORKSPACE..."
for repo in "${REPOS[@]}"; do
  dest="$WORKSPACE/$repo"
  if [ -d "$dest" ]; then
    echo "  [skip] $repo (already exists)"
  else
    echo "  [clone] $repo"
    git clone "git@github.com:zaeemadamjee/$repo.git" "$dest"
  fi
done

echo "==> Done."
