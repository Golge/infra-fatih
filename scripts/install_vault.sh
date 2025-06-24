#!/bin/bash

# HashiCorp Vault Installation
# This script installs HashiCorp Vault using Helm

set -e

echo "🔒 Installing HashiCorp Vault..."

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

# Add HashiCorp Helm repository
echo "📚 Adding HashiCorp Helm repository..."
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Create namespace for Vault
echo "🏗️ Creating vault namespace..."
kubectl create namespace vault || echo "Namespace already exists"

# Create Vault values file
echo "📝 Creating Vault configuration..."
cat > /tmp/vault-values.yaml <<EOF
server:
  dev:
    enabled: true
    devRootToken: "root"
  dataStorage:
    enabled: true
    size: 10Gi
    storageClass: nfs-client
  resources:
    requests:
      memory: 128Mi
      cpu: 50m
    limits:
      memory: 512Mi
      cpu: 250m
  service:
    type: NodePort
    nodePort: 30090
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
      - host: vault.local
        paths:
          - /
ui:
  enabled: true
  serviceType: ClusterIP
EOF

# Install or upgrade Vault
if helm list -n vault | grep -q vault; then
    echo "Vault already installed, upgrading..."
    helm upgrade vault hashicorp/vault \
        --namespace vault \
        --values /tmp/vault-values.yaml
else
    echo "Installing Vault..."
    helm install vault hashicorp/vault \
        --namespace vault \
        --values /tmp/vault-values.yaml
fi

# Wait for Vault to be ready
echo "⏳ Waiting for Vault to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n vault --timeout=300s

echo "✅ HashiCorp Vault installed successfully!"
echo ""
echo "📋 Vault Details:"
echo "• Namespace: vault"
echo "• Access URL: http://vault.local (add to /etc/hosts)"
echo "• Root Token: root (dev mode)"
echo "• Mode: Development (not for production!)"

echo ""
echo "🌐 To access Vault:"
echo "1. Get the NodePort:"
echo "   kubectl get svc -n vault vault"
echo "2. Access via: http://<node-ip>:<nodeport>"
echo "3. Or add vault.local to /etc/hosts and use ingress"

echo ""
echo "⚠️  Important: This is a development installation!"
echo "   - Data is not persisted in dev mode"
echo "   - Use production configuration for real deployments"

# Clean up
rm -f /tmp/vault-values.yaml

echo ""
echo "🔍 To check Vault status:"
echo "kubectl get pods -n vault"
echo "kubectl get svc -n vault"
