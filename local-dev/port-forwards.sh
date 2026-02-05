#!/bin/bash

echo "Starting port forwards..."
echo ""
echo "Services will be available at:"
echo "  - ArgoCD UI:  http://localhost:8080"
echo "  - Frontend:   http://localhost:8081"
echo "  - API:        http://localhost:8082"
echo ""
echo "Press Ctrl+C to stop all port forwards"
echo ""

# Kill any existing port forwards
pkill -f "port-forward.*8080" 2>/dev/null || true
pkill -f "port-forward.*8081" 2>/dev/null || true
pkill -f "port-forward.*8082" 2>/dev/null || true

# Give processes time to die
sleep 1

# Start port forwards in background
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
ARGOCD_PID=$!

kubectl port-forward svc/frontend -n dev 8081:80 2>/dev/null &
FRONTEND_PID=$!

kubectl port-forward svc/api -n dev 8082:3000 2>/dev/null &
API_PID=$!

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Stopping port forwards..."
    kill $ARGOCD_PID 2>/dev/null || true
    kill $FRONTEND_PID 2>/dev/null || true
    kill $API_PID 2>/dev/null || true
    exit 0
}

# Trap Ctrl+C
trap cleanup INT TERM

# Wait for all background processes
wait
