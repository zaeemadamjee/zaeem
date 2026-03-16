#!/usr/bin/env bash
# clone-repos.sh — Clone pinecone-io repos into ~/workspace/.
#
# Requires SSH agent forwarding (run after SSHing in via start.sh).
# Safe to re-run — skips repos that already exist.

set -euo pipefail

WORKSPACE="$HOME/workspace"
mkdir -p "$WORKSPACE"

REPOS=(
  deploy-log
  python-sdk
  pinecone-python-client
  pinecone-ts-client
  pinecone-java-client
  go-pinecone
  pinecone-rust-client
  pclocal
  pinecone-db
  pinecone-internal-claude-plugins
  pinecone-mcp
  pinecone-datasets
  examples
  docs
)

echo "==> Cloning pinecone-io repos into $WORKSPACE..."
for repo in "${REPOS[@]}"; do
  dest="$WORKSPACE/$repo"
  if [ -d "$dest" ]; then
    echo "  [skip] $repo (already exists)"
  else
    echo "  [clone] $repo"
    git clone "git@github.com:pinecone-io/$repo.git" "$dest"
  fi
done

echo "==> Done."
