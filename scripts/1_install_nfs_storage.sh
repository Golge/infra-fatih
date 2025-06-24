#!/bin/bash

# NFS Storage Class Installation
# This script sets up NFS-based storage class for Kubernetes

set -e

echo "🚀 Setting up NFS Storage Class..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ Helm not found. Please install Helm first."
    exit 1
fi

# Add NFS Subdir External Provisioner Helm repository
echo "📚 Adding NFS Subdir External Provisioner Helm repository..."
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update

# Create namespace for nfs-provisioner
echo "🏗️ Creating nfs-provisioner namespace..."
kubectl create namespace nfs-provisioner || echo "Namespace already exists"

# Get the worker node's internal IP for NFS server (more resources available)
echo "🔍 Getting worker node IP for NFS server..."
WORKER_IP=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "Using worker node IP: $WORKER_IP"

# Install NFS Subdir External Provisioner
echo "📦 Installing NFS Subdir External Provisioner..."
if helm list -n nfs-provisioner | grep -q nfs-subdir-external-provisioner; then
    echo "NFS provisioner already installed, upgrading..."
    helm upgrade nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
        --namespace nfs-provisioner \
        --set nfs.server=$WORKER_IP \
        --set nfs.path=/nfs/data \
        --set storageClass.name=nfs-client \
        --set storageClass.defaultClass=true \
        --set storageClass.reclaimPolicy=Retain
else
    helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
        --namespace nfs-provisioner \
        --set nfs.server=$WORKER_IP \
        --set nfs.path=/nfs/data \
        --set storageClass.name=nfs-client \
        --set storageClass.defaultClass=true \
        --set storageClass.reclaimPolicy=Retain
fi

# Wait for the provisioner to be ready
echo "⏳ Waiting for NFS provisioner to be ready..."
kubectl wait --namespace nfs-provisioner \
    --for=condition=ready pod \
    --selector=app=nfs-subdir-external-provisioner \
    --timeout=300s

# Create a test PVC to verify NFS storage
echo "🧪 Creating test PVC to verify NFS storage..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-nfs-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: nfs-client
EOF

echo "✅ NFS Storage Class installation completed!"
echo ""
echo "To verify the installation:"
echo "kubectl get storageclass"
echo "kubectl get pvc test-nfs-pvc"
echo "kubectl get pods -n nfs-provisioner"
echo ""
echo "To clean up the test PVC:"
echo "kubectl delete pvc test-nfs-pvc"
