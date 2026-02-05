#!/bin/bash
set -e

CLUSTER_NAME="argocd-demo"

echo "Starting Minikube cluster: $CLUSTER_NAME"

# Start with recommended settings for ArgoCD
minikube start \
    -p "$CLUSTER_NAME" \
    --cpus=4 \
    --memory=8192 \
    --disk-size=20g \
    --driver=docker \
    --kubernetes-version=stable

echo ""
echo "Cluster '$CLUSTER_NAME' is running!"
echo ""
echo "To use kubectl with this cluster:"
echo "  kubectl config use-context $CLUSTER_NAME"
echo ""
echo "To open dashboard:"
echo "  minikube dashboard -p $CLUSTER_NAME"
