#!/bin/bash
set -e

CLUSTER_NAME="argocd-demo"

echo "========================================"
echo "  Cleanup - K8s GitOps Demo"
echo "========================================"
echo ""
echo "This will:"
echo "  - Stop all port forwards"
echo "  - Delete Minikube cluster '$CLUSTER_NAME'"
echo ""
read -p "Are you sure? (y/N) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

# Stop port forwards
echo "Stopping port forwards..."
pkill -f 'port-forward' 2>/dev/null || true

# Delete Minikube cluster
echo "Deleting Minikube cluster..."
minikube delete -p "$CLUSTER_NAME" 2>/dev/null || true

echo ""
echo "Cleanup complete!"
echo ""
echo "To start fresh: ./scripts/00-run-all.sh"
