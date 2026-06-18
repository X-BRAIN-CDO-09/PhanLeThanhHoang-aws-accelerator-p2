#!/bin/bash
# Phase 3: Build & Push images to GHCR (run from local machine)
# This script builds both backend + frontend images and pushes to GHCR.
# After pushing, EC2 minikube can pull them without needing local image load.
#
# Prerequisites:
#   1. Docker installed and running
#   2. Logged into GHCR: echo $GITHUB_TOKEN | docker login ghcr.io -u <username> --password-stdin
#   3. GITHUB_TOKEN needs 'write:packages' scope
#
# Usage:
#   cd cloud/w10/flipkart
#   chmod +x build-push-ghcr.sh
#   ./build-push-ghcr.sh

set -euxo pipefail

# --- Configuration ---
REGISTRY="ghcr.io"
IMAGE_OWNER="x-brain-cdo-09"   # lowercase required by GHCR
TAG="latest"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTEXT="${SCRIPT_DIR}"

BACKEND_IMAGE="${REGISTRY}/${IMAGE_OWNER}/flipkart-backend"
FRONTEND_IMAGE="${REGISTRY}/${IMAGE_OWNER}/flipkart-frontend"

echo "=== Building backend image ==="
docker build -t "${BACKEND_IMAGE}:${TAG}" -f "${CONTEXT}/Dockerfile.backend" "${CONTEXT}"

echo "=== Building frontend image ==="
docker build -t "${FRONTEND_IMAGE}:${TAG}" -f "${CONTEXT}/Dockerfile.frontend" "${CONTEXT}"

echo "=== Pushing backend image ==="
docker push "${BACKEND_IMAGE}:${TAG}"

echo "=== Pushing frontend image ==="
docker push "${FRONTEND_IMAGE}:${TAG}"

echo ""
echo "=== Done! ==="
echo "Backend:  ${BACKEND_IMAGE}:${TAG}"
echo "Frontend: ${FRONTEND_IMAGE}:${TAG}"
echo ""
echo "Next steps:"
echo "  1. Make GHCR packages public (Settings -> Packages -> Package settings -> Danger zone -> Make public)"
echo "     OR create imagePullSecret in flipkart namespace"
echo "  2. If using Cosign (W10 Lab 2.2), sign the images:"
echo "     cosign sign --key cosign.key ${BACKEND_IMAGE}:${TAG}"
echo "     cosign sign --key cosign.key ${FRONTEND_IMAGE}:${TAG}"
echo "  3. Run terraform apply to create EC2"
echo "  4. SSH into EC2 and verify pods are running"
