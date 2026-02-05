#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CLUSTER_NAME="argocd-demo"
NAMESPACE="${1:-local}"

echo "========================================"
echo "  Local Deploy (bypasses ArgoCD)"
echo "========================================"
echo ""
echo "This script deploys directly to Kubernetes"
echo "without going through ArgoCD. Useful for"
echo "quick local testing."
echo ""
echo "Namespace: $NAMESPACE"
echo ""

# Check if Minikube is running
if ! minikube status -p "$CLUSTER_NAME" &> /dev/null; then
    echo "Error: Minikube cluster '$CLUSTER_NAME' is not running"
    echo "Start it with: ./scripts/01-setup-cluster.sh"
    exit 1
fi

# Point docker to Minikube's docker daemon
echo "Configuring Docker to use Minikube's daemon..."
eval $(minikube -p "$CLUSTER_NAME" docker-env)

# Build images
echo ""
echo "Building frontend..."
cd "$PROJECT_DIR/apps/frontend"
pnpm install
pnpm build
docker build -t ghcr.io/barsukov/frontend:local .

echo ""
echo "Building API..."
cd "$PROJECT_DIR/apps/api"
pnpm install
pnpm build
docker build -t ghcr.io/barsukov/api:local .

# Reset docker env
eval $(minikube -p "$CLUSTER_NAME" docker-env --unset)

# Create namespace if it doesn't exist
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Deploy using kustomize with local image tags
echo ""
echo "Deploying to namespace: $NAMESPACE"

# Create temporary kustomization with local tags
cd "$PROJECT_DIR"

# Deploy API
echo "Deploying API..."
kustomize build apps/api/k8s/overlays/dev | \
    sed 's|ghcr.io/barsukov/api:latest|ghcr.io/barsukov/api:local|g' | \
    sed "s|namespace: dev|namespace: $NAMESPACE|g" | \
    kubectl apply -f -

# Deploy Frontend
echo "Deploying Frontend..."
kustomize build apps/frontend/k8s/overlays/dev | \
    sed 's|ghcr.io/barsukov/frontend:latest|ghcr.io/barsukov/frontend:local|g' | \
    sed "s|namespace: dev|namespace: $NAMESPACE|g" | \
    kubectl apply -f -

# Wait for deployments
echo ""
echo "Waiting for deployments to be ready..."
kubectl rollout status deployment/api -n "$NAMESPACE" --timeout=120s
kubectl rollout status deployment/frontend -n "$NAMESPACE" --timeout=120s

# Show status
echo ""
echo "Deployment status:"
kubectl get pods -n "$NAMESPACE"
kubectl get services -n "$NAMESPACE"

# Port forward
echo ""
echo "Starting port forwards..."
echo "  Frontend: http://localhost:8081"
echo "  API:      http://localhost:8082"
echo ""
echo "Press Ctrl+C to stop port forwards"

# Kill any existing port forwards
pkill -f "port-forward.*8081" 2>/dev/null || true
pkill -f "port-forward.*8082" 2>/dev/null || true

# Start port forwards
kubectl port-forward -n "$NAMESPACE" svc/frontend 8081:80 &
kubectl port-forward -n "$NAMESPACE" svc/api 8082:3000 &

wait
