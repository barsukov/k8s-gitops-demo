#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CLUSTER_NAME="argocd-demo"

echo "Building and loading images to Minikube..."

# Point docker to Minikube's docker daemon
echo "Configuring Docker to use Minikube's daemon..."
eval $(minikube -p "$CLUSTER_NAME" docker-env)

# Build frontend
echo ""
echo "Building frontend image..."
cd "$PROJECT_DIR/apps/frontend"

# Install dependencies and build
pnpm install
pnpm build

# Build Docker image
docker build -t ghcr.io/barsukov/frontend:local -t ghcr.io/barsukov/frontend:latest .

# Build API
echo ""
echo "Building API image..."
cd "$PROJECT_DIR/apps/api"

# Install dependencies and build
pnpm install
pnpm build

# Build Docker image
docker build -t ghcr.io/barsukov/api:local -t ghcr.io/barsukov/api:latest .

# Reset docker env
eval $(minikube -p "$CLUSTER_NAME" docker-env --unset)

echo ""
echo "Images built and available in Minikube!"
echo ""
echo "Built images:"
echo "  - ghcr.io/barsukov/frontend:local"
echo "  - ghcr.io/barsukov/frontend:latest"
echo "  - ghcr.io/barsukov/api:local"
echo "  - ghcr.io/barsukov/api:latest"
