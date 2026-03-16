#!/usr/bin/env bash
# start.sh — Start the dev box and SSH into it.
#
# Usage: ./scripts/start.sh
#
# On first run, adds a "devbox" entry to ~/.ssh/config.
# On subsequent runs, updates the HostName with the new ephemeral IP.

set -euo pipefail

INSTANCE="zaeem-devbox"
ZONE="us-central1-a"
PROJECT="zaeem-dev"
SSH_KEY="$HOME/.ssh/zaeem_devbox"
SSH_USER="zaeem"
SSH_CONFIG="$HOME/.ssh/config"

echo "==> Starting $INSTANCE..."
gcloud compute instances start "$INSTANCE" --zone="$ZONE" --project="$PROJECT" --quiet

echo "==> Waiting for SSH to be ready..."
IP=""
SSH_READY="false"
for i in $(seq 1 30); do
  IP=$(gcloud compute instances describe "$INSTANCE" \
    --zone="$ZONE" --project="$PROJECT" \
    --format="get(networkInterfaces[0].accessConfigs[0].natIP)" 2>/dev/null || true)
  if [ -n "$IP" ] && ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no \
       -o BatchMode=yes -i "$SSH_KEY" "${SSH_USER}@${IP}" true 2>/dev/null; then
    SSH_READY="true"
    break
  fi
  echo "  attempt $i/30..."
  sleep 3
done

if [ -z "$IP" ] || [ "$SSH_READY" != "true" ]; then
  echo "ERROR: Could not reach VM over SSH after 30 attempts" >&2
  exit 1
fi

echo "==> VM is up at $IP"

echo "==> Copying Ghostty terminfo to devbox..."
infocmp -x | ssh -i "$SSH_KEY" "${SSH_USER}@${IP}" -- tic -x -

# Patch or create ~/.ssh/config entry
touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

if grep -q "^Host devbox$" "$SSH_CONFIG" 2>/dev/null; then
  # Update existing entry
  python3 - "$SSH_CONFIG" "$IP" <<'PYEOF'
import sys, re
config_file, new_ip = sys.argv[1], sys.argv[2]
with open(config_file) as f:
    content = f.read()
# Replace HostName only within the Host devbox block
content = re.sub(
    r'(Host devbox\n(?:[ \t]+\S.*\n)*?[ \t]+HostName )\S+',
    lambda m: m.group(1) + new_ip,
    content
)
with open(config_file, 'w') as f:
    f.write(content)
PYEOF
  echo "==> Updated SSH config (HostName -> $IP)"
else
  # Add new entry
  cat >> "$SSH_CONFIG" <<EOF

Host devbox
  HostName $IP
  User $SSH_USER
  IdentityFile $SSH_KEY
  StrictHostKeyChecking no
  ForwardAgent yes
EOF
  echo "==> Added devbox to SSH config"
fi

echo "==> Connecting to devbox (will auto-attach to tmux session)..."
ssh devbox
