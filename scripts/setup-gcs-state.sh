#!/usr/bin/env bash
# =============================================================================
# setup-gcs-state.sh
#
# Bootstraps the GCS bucket used for Terraform remote state storage.
# This script must be run BEFORE `terraform init` since the backend bucket
# must exist before Terraform can initialize the remote backend.
#
# GCS bucket names are globally unique. If `zaeem-tf-state` is already taken
# by another GCP project, choose a different name and update the bucket name
# in terraform/main.tf (backend "gcs" block) as well as this script.
#
# Usage:
#   ./scripts/setup-gcs-state.sh
#
# Requirements:
#   - gcloud CLI authenticated with sufficient permissions
#   - Target GCP project: zaeem-dev
# =============================================================================

set -euo pipefail

PROJECT="zaeem-dev"
BUCKET_NAME="zaeem-tf-state"
BUCKET_URI="gs://${BUCKET_NAME}"
LOCATION="US"

echo "==> Checking for existing GCS bucket: ${BUCKET_URI}"

if gcloud storage buckets describe "${BUCKET_URI}" --project="${PROJECT}" &>/dev/null; then
  echo "    Bucket ${BUCKET_URI} already exists — skipping creation."
else
  echo "==> Creating bucket ${BUCKET_URI} in location ${LOCATION}..."
  gcloud storage buckets create "${BUCKET_URI}" \
    --project="${PROJECT}" \
    --location="${LOCATION}" \
    --uniform-bucket-level-access

  echo "==> Enabling versioning on ${BUCKET_URI}..."
  gcloud storage buckets update "${BUCKET_URI}" \
    --versioning

  echo "    Bucket created and versioning enabled."
fi

echo ""
echo "==> Success! GCS state bucket is ready: ${BUCKET_URI}"
echo ""
echo "Next steps:"
echo "  1. cd terraform/"
echo "  2. terraform init"
echo "  3. terraform plan"
