#!/usr/bin/env bash
# profiles/personal.sh — Profile for the personal devbox VM.

PROFILE_NAME="pc-zaeem"

# --- GCP settings ---
GCP_PROJECT="development-pinecone"
GCP_REGION="us-central1"
GCP_INSTANCE_NAME="pc-zaeem"

# --- VM hardware ---
VM_MACHINE_TYPE="e2-standard-2"
VM_DISK_SIZE=50

# --- Features ---
IDLE_TIMER_ENABLED=true
STATIC_IP=false

# --- SSH public keys ---
# Add one entry per machine that needs SSH access to this VM.
# Get the value with: cat ~/.ssh/zaeem_devbox.pub
SSH_PUBLIC_KEYS=(
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIe+dhl8N8R4pgSsywyXYywnRf9bfNGlTDVT0Z1RJ3GF zaeem-devbox"
  # "ssh-ed25519 AAAA... zaeem@machine2"
)

# --- Firewall: extra TCP ports to open (beyond SSH/22) ---
# Examples: "3000" (dev server), "8080" (proxy), "5432" (postgres)
FIREWALL_ALLOW_PORTS=(
)

# --- Repos to clone into ~/workspace on first login ---
REPOS=(
  "git@github.com:pinecone-io/management-console.git"
)
