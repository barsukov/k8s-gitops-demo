#!/bin/bash
set -e

echo "Configuring ArgoCD..."

# Patch ArgoCD ConfigMap for faster reconciliation (30s instead of 3m default)
kubectl patch configmap argocd-cm -n argocd --type merge -p '
{
  "data": {
    "timeout.reconciliation": "30s"
  }
}'

# Restart ArgoCD components to pick up config changes
echo "Restarting ArgoCD components..."
kubectl rollout restart deployment argocd-repo-server -n argocd
kubectl rollout restart deployment argocd-applicationset-controller -n argocd

# Wait for restart to complete
kubectl rollout status deployment argocd-repo-server -n argocd --timeout=120s
kubectl rollout status deployment argocd-applicationset-controller -n argocd --timeout=120s

echo ""
echo "ArgoCD configuration complete!"
echo "  - Reconciliation interval: 30s"
