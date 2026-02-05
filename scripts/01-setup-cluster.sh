#!/bin/bash
set -e

CLUSTER_NAME="argocd-demo"

echo "Setting up Minikube cluster: $CLUSTER_NAME"

# Check if minikube is installed
if ! command -v minikube &> /dev/null; then
    echo "Error: minikube is not installed"
    echo "Install with: brew install minikube"
    exit 1
fi

# Check if cluster already exists
if minikube status -p "$CLUSTER_NAME" &> /dev/null; then
    echo "Cluster '$CLUSTER_NAME' already exists"
    read -p "Delete and recreate? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        minikube delete -p "$CLUSTER_NAME"
    else
        echo "Using existing cluster"
        minikube start -p "$CLUSTER_NAME"
        exit 0
    fi
fi

# Start Minikube with recommended settings
echo "Starting Minikube..."
minikube start \
    -p "$CLUSTER_NAME" \
    --cpus=4 \
    --memory=8192 \
    --disk-size=20g \
    --driver=docker \
    --kubernetes-version=stable

# Enable useful addons
echo "Enabling addons..."
minikube addons enable metrics-server -p "$CLUSTER_NAME"
minikube addons enable dashboard -p "$CLUSTER_NAME"

# Verify cluster is running
echo "Verifying cluster..."
kubectl cluster-info
kubectl get nodes

echo ""
echo "Minikube cluster '$CLUSTER_NAME' is ready!"
echo ""
echo "Useful commands:"
echo "  minikube dashboard -p $CLUSTER_NAME    # Open Kubernetes dashboard"
echo "  minikube stop -p $CLUSTER_NAME         # Stop cluster"
echo "  minikube delete -p $CLUSTER_NAME       # Delete cluster"
