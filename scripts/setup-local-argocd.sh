#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================"
echo "  Setup Local ArgoCD Testing"
echo "========================================"
echo ""
echo "This configures ArgoCD to watch your local"
echo "git repository using file:// URLs."
echo ""
echo "After setup:"
echo "  1. Make changes to your code"
echo "  2. Commit locally (git add . && git commit -m 'test')"
echo "  3. ArgoCD automatically syncs to 'local' namespace"
echo ""
echo "No git push required!"
echo ""

# Check if the project is a git repo
if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo "Warning: Project is not a git repository"
    echo "Initializing git repo..."
    cd "$PROJECT_DIR"
    git init
    git add .
    git commit -m "Initial commit for local ArgoCD testing"
fi

# Create local namespace
kubectl create namespace local --dry-run=client -o yaml | kubectl apply -f -

# Apply local project
echo "Creating local ArgoCD project..."
kubectl apply -f "$PROJECT_DIR/argocd/projects/local-project.yaml"

# Apply local applications
echo "Creating local ArgoCD applications..."
kubectl apply -f "$PROJECT_DIR/argocd/applications/local/"

echo ""
echo "Local ArgoCD testing is now configured!"
echo ""
echo "Applications created:"
kubectl get applications -n argocd | grep local

echo ""
echo "To test the workflow:"
echo "  1. Make a change to apps/frontend/src/App.tsx"
echo "  2. git add . && git commit -m 'test change'"
echo "  3. Watch ArgoCD sync: kubectl get applications -n argocd -w"
echo "  4. Check the result: http://localhost:8081"
echo ""
echo "To start port forwards:"
echo "  ./local-dev/port-forwards.sh"
