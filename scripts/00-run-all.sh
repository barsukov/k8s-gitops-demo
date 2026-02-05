#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================"
echo "  K8s GitOps Demo - Full Setup"
echo "========================================"
echo ""
echo "This script will:"
echo "  1. Start Minikube cluster"
echo "  2. Install ArgoCD"
echo "  3. Configure ArgoCD"
echo "  4. Build and load images"
echo "  5. Deploy applications"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

cd "$PROJECT_DIR"

echo ""
echo "[1/5] Setting up Minikube cluster..."
"$SCRIPT_DIR/01-setup-cluster.sh"

echo ""
echo "[2/5] Installing ArgoCD..."
"$SCRIPT_DIR/02-install-argocd.sh"

echo ""
echo "[3/5] Configuring ArgoCD..."
"$SCRIPT_DIR/03-configure-argocd.sh"

echo ""
echo "[4/5] Building and loading images..."
"$SCRIPT_DIR/04-build-images.sh"

echo ""
echo "[5/5] Deploying applications..."
"$SCRIPT_DIR/05-deploy-apps.sh"

echo ""
echo "========================================"
echo "  Setup Complete!"
echo "========================================"
echo ""
echo "Access Points:"
echo "  - ArgoCD UI:  http://localhost:8080"
echo "  - Frontend:   http://localhost:8081"
echo "  - API:        http://localhost:8082"
echo ""
echo "ArgoCD Credentials:"
echo "  - Username: admin"
echo -n "  - Password: "
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
echo ""
echo "Port forwards are running in the background."
echo "To stop them: pkill -f 'port-forward'"
echo ""
echo "To clean up: ./scripts/99-cleanup-all.sh"
