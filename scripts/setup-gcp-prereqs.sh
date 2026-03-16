#!/usr/bin/env bash
# setup-gcp-prereqs.sh
#
# Prepares GCP prerequisites for the cloud dev box project.
#
# What this script does:
#   1. Enables the required GCP APIs (Compute Engine, Cloud Storage) on the
#      target project.  Re-running is safe — enabling an already-enabled API
#      is a no-op.
#   2. Ensures an ed25519 SSH key exists at ~/.ssh/zaeem_devbox.  If the key
#      is already present it is left untouched; otherwise it is generated.
#   3. Prints the public key so it can be supplied to Terraform (e.g. as the
#      value of the `ssh_public_key` variable).
#
# Prerequisites:
#   - gcloud CLI installed and authenticated (`gcloud auth login`)
#   - Sufficient IAM permissions to enable APIs on the target project
#
# Usage:
#   bash scripts/setup-gcp-prereqs.sh
#
# Safe to run more than once (idempotent).

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
GCP_PROJECT="zaeem-dev"
SSH_KEY_PATH="${HOME}/.ssh/zaeem_devbox"
SSH_KEY_COMMENT="zaeem-devbox"

REQUIRED_APIS=(
  "compute.googleapis.com"
  "storage.googleapis.com"
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()    { printf '\033[0;34m[INFO]\033[0m  %s\n' "$*"; }
success() { printf '\033[0;32m[OK]\033[0m    %s\n' "$*"; }
warn()    { printf '\033[0;33m[WARN]\033[0m  %s\n' "$*"; }

# ---------------------------------------------------------------------------
# 1. Enable required GCP APIs
# ---------------------------------------------------------------------------
info "Enabling required GCP APIs on project '${GCP_PROJECT}'..."

for api in "${REQUIRED_APIS[@]}"; do
  info "  Enabling ${api} ..."
  gcloud services enable "${api}" --project="${GCP_PROJECT}"
  success "  ${api} is enabled."
done

# ---------------------------------------------------------------------------
# 2. Ensure SSH key exists
# ---------------------------------------------------------------------------
if [[ -f "${SSH_KEY_PATH}" ]]; then
  success "SSH key already exists at ${SSH_KEY_PATH} — skipping generation."
else
  info "SSH key not found. Generating ed25519 key at ${SSH_KEY_PATH} ..."
  ssh-keygen -t ed25519 -C "${SSH_KEY_COMMENT}" -f "${SSH_KEY_PATH}" -N ""
  success "SSH key generated."
fi

# ---------------------------------------------------------------------------
# 3. Print public key for Terraform
# ---------------------------------------------------------------------------
echo ""
info "=== Public key (needed for Terraform) ==="
echo ""
cat "${SSH_KEY_PATH}.pub"
echo ""
warn "Copy the public key above and supply it as the 'ssh_public_key' Terraform variable."
