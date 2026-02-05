#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Deploying ArgoCD applications..."

# Apply ArgoCD projects
echo "Creating ArgoCD projects..."
kubectl apply -f "$PROJECT_DIR/argocd/projects/"

# Create namespaces
echo "Creating namespaces..."
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace local --dry-run=client -o yaml | kubectl apply -f -

# Apply dev applications
echo "Deploying dev applications..."
kubectl apply -f "$PROJECT_DIR/argocd/applications/dev/"

# Start port forwards in background
echo "Starting port forwards..."
"$SCRIPT_DIR/../local-dev/port-forwards.sh" &

# Wait for apps to sync
echo ""
echo "Waiting for applications to sync..."
sleep 10

# Show application status
echo ""
echo "Application status:"
kubectl get applications -n argocd

echo ""
echo "Deployment complete!"
echo ""
echo "Note: Production apps are NOT deployed by default."
echo "To deploy production apps:"
echo "  kubectl apply -f argocd/applications/prod/"
echo ""
echo "To use local ArgoCD testing (file:// repos):"
echo "  kubectl apply -f argocd/applications/local/"
