#!/bin/bash

# NGINX Ingress Controller Installation for GCE
# This script installs NGINX Ingress Controller using Helm

set -e

echo "🚀 Installing NGINX Ingress Controller..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "📦 Helm not found. Installing Helm..."
    # Use snap for more reliable installation
    if command -v snap &> /dev/null; then
        sudo snap install helm --classic
    else
        # Fallback to manual installation
        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
        chmod 700 get_helm.sh
        timeout 60 ./get_helm.sh || {
            echo "⚠️ Helm installation timed out. Installing manually..."
            wget https://get.helm.sh/helm-v3.18.3-linux-amd64.tar.gz
            tar -zxvf helm-v3.18.3-linux-amd64.tar.gz
            sudo mv linux-amd64/helm /usr/local/bin/helm
            rm -rf linux-amd64 helm-v3.18.3-linux-amd64.tar.gz
        }
    fi
fi

# Add NGINX Ingress Helm repository
echo "📚 Adding NGINX Ingress Helm repository..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Create namespace for ingress-nginx
echo "🏗️ Creating ingress-nginx namespace..."
kubectl create namespace ingress-nginx || echo "Namespace already exists"

# Install NGINX Ingress Controller with LoadBalancer service type for GCE
echo "⚙️ Installing NGINX Ingress Controller..."
if helm list -n ingress-nginx | grep -q ingress-nginx; then
    echo "NGINX Ingress already installed, upgrading..."
    helm upgrade ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --set controller.service.type=NodePort \
        --set controller.service.nodePorts.http=30080 \
        --set controller.service.nodePorts.https=30443 \
        --set controller.publishService.enabled=false \
        --set controller.replicaCount=2 \
        --set controller.nodeSelector."kubernetes\.io/os"=linux \
        --set defaultBackend.enabled=true
else
    helm install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --set controller.service.type=NodePort \
        --set controller.service.nodePorts.http=30080 \
        --set controller.service.nodePorts.https=30443 \
        --set controller.publishService.enabled=false \
        --set controller.replicaCount=2 \
        --set controller.nodeSelector."kubernetes\.io/os"=linux \
        --set defaultBackend.enabled=true
fi

# Wait for the ingress controller to be ready
echo "⏳ Waiting for NGINX Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=300s

# Get the external IP
echo "🔍 Getting External IP (this may take a few minutes)..."
echo "Run the following command to check the external IP:"
echo "kubectl get svc -n ingress-nginx ingress-nginx-controller"

echo "✅ NGINX Ingress Controller installation completed!"
echo ""
echo "To verify the installation:"
echo "kubectl get pods -n ingress-nginx"
echo "kubectl get svc -n ingress-nginx"
