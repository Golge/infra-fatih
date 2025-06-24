#!/bin/bash

# ArgoCD Installation
# This script installs ArgoCD using Helm

set -e

echo "🔄 Installing ArgoCD..."

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

# Add Argo Helm repository
echo "📚 Adding Argo Helm repository..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Create namespace for ArgoCD
echo "🏗️ Creating argocd namespace..."
kubectl create namespace argocd || echo "Namespace already exists"

# Install or upgrade ArgoCD
if helm list -n argocd | grep -q argocd; then
    echo "ArgoCD already installed, upgrading..."
    helm upgrade argocd argo/argo-cd \
        --namespace argocd \
        --set server.service.type=NodePort \
        --set server.service.nodePortHttp=30081 \
        --set server.service.nodePortHttps=30444 \
        --set configs.params."server\.insecure"=true \
        --set server.resources.requests.cpu="50m" \
        --set server.resources.requests.memory="128Mi" \
        --set server.resources.limits.cpu="500m" \
        --set server.resources.limits.memory="512Mi" \
        --set controller.resources.requests.cpu="100m" \
        --set controller.resources.requests.memory="256Mi" \
        --set controller.resources.limits.cpu="500m" \
        --set controller.resources.limits.memory="1Gi"
else
    echo "Installing ArgoCD..."
    helm install argocd argo/argo-cd \
        --namespace argocd \
        --set server.service.type=NodePort \
        --set server.service.nodePortHttp=30081 \
        --set server.service.nodePortHttps=30444 \
        --set configs.params."server\.insecure"=true \
        --set server.resources.requests.cpu="50m" \
        --set server.resources.requests.memory="128Mi" \
        --set server.resources.limits.cpu="500m" \
        --set server.resources.limits.memory="512Mi" \
        --set controller.resources.requests.cpu="100m" \
        --set controller.resources.requests.memory="256Mi" \
        --set controller.resources.limits.cpu="500m" \
        --set controller.resources.limits.memory="1Gi"
fi

# Wait for ArgoCD components to be ready
echo "⏳ Waiting for ArgoCD components to be ready..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
kubectl wait --for=condition=available deployment/argocd-repo-server -n argocd --timeout=300s
kubectl wait --for=condition=available deployment/argocd-dex-server -n argocd --timeout=300s

echo "✅ ArgoCD installed successfully!"
echo ""
echo "📋 ArgoCD Details:"
echo "• Namespace: argocd"
echo "• Access URL: http://argocd.local (add to /etc/hosts)"
echo "• Username: admin"

echo ""
echo "🔑 ArgoCD admin password:"
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode
echo ""

echo ""
echo "🌐 To access ArgoCD:"
echo "1. Get the NodePort:"
echo "   kubectl get svc -n argocd argocd-server"
echo "2. Access via: http://<node-ip>:<nodeport>"
echo "3. Or add argocd.local to /etc/hosts and use ingress"

echo ""
echo "🚀 ArgoCD CLI installation:"
echo "   curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
echo "   sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd"
echo "   rm argocd-linux-amd64"

echo ""
echo "🔍 To check ArgoCD status:"
echo "kubectl get pods -n argocd"
echo "kubectl get svc -n argocd"
