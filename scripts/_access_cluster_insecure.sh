#!/bin/bash

# Quick access to cluster by skipping TLS verification
# WARNING: This is less secure but works immediately

echo "Setting up insecure cluster access..."

# Create a new context that skips TLS verification
kubectl config set-cluster cluster.local-insecure \
  --server=https://34.12.39.41:6443 \
  --insecure-skip-tls-verify=true

kubectl config set-context kubernetes-admin@cluster.local-insecure \
  --cluster=cluster.local-insecure \
  --user=kubernetes-admin

# Switch to the insecure context
kubectl config use-context kubernetes-admin@cluster.local-insecure

echo "Testing cluster access..."
kubectl get nodes

echo ""
echo "Cluster access configured with TLS verification disabled."
echo "To switch back to secure context: kubectl config use-context kubernetes-admin@cluster.local"
