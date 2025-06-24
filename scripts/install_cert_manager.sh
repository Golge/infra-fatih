#!/bin/bash

# Cert-Manager Installation
# This script installs Cert-Manager using Helm

set -e

echo "🔐 Installing Cert-Manager..."

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

# Add Jetstack Helm repository
echo "📚 Adding Jetstack Helm repository..."
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Create namespace for cert-manager
echo "🏗️ Creating cert-manager namespace..."
kubectl create namespace cert-manager || echo "Namespace already exists"

# Install or upgrade Cert-Manager
if helm list -n cert-manager | grep -q cert-manager; then
    echo "Cert-Manager already installed, upgrading..."
    helm upgrade cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --version v1.13.2 \
        --set installCRDs=true \
        --set global.leaderElection.namespace=cert-manager
else
    echo "Installing Cert-Manager..."
    helm install cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --version v1.13.2 \
        --set installCRDs=true \
        --set global.leaderElection.namespace=cert-manager
fi

# Wait for cert-manager components to be ready
echo "⏳ Waiting for cert-manager components to be ready..."
kubectl wait --for=condition=available deployment/cert-manager -n cert-manager --timeout=300s
kubectl wait --for=condition=available deployment/cert-manager-cainjector -n cert-manager --timeout=300s
kubectl wait --for=condition=available deployment/cert-manager-webhook -n cert-manager --timeout=300s

echo "✅ Cert-Manager installed successfully!"
echo ""
echo "📋 Cert-Manager Details:"
echo "• Namespace: cert-manager"
echo "• Version: v1.13.2"
echo "• CRDs installed: Yes"

echo ""
echo "📝 Next steps:"
echo "1. Create ClusterIssuer for Let's Encrypt:"
echo "   kubectl apply -f https://cert-manager.io/docs/tutorials/acme/example/staging-issuer.yaml"
echo ""
echo "2. Or create a self-signed ClusterIssuer:"
cat <<EOF
echo "   kubectl apply -f - <<EOL
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
EOL"
EOF

echo ""
echo "🔍 To check Cert-Manager status:"
echo "kubectl get pods -n cert-manager"
echo "kubectl get clusterissuers"
