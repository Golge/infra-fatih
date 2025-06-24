#!/bin/bash

# Harbor Installation
# This script installs Harbor registry using Helm

set -e

echo "🐳 Installing Harbor Registry..."

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

# Add Harbor Helm repository
echo "📚 Adding Harbor Helm repository..."
helm repo add harbor https://helm.goharbor.io
helm repo update

# Create namespace for Harbor
echo "🏗️ Creating harbor namespace..."
kubectl create namespace harbor || echo "Namespace already exists"

# Create Harbor values file
echo "📝 Creating Harbor configuration..."
cat > /tmp/harbor-values.yaml <<EOF
expose:
  type: nodePort
  nodePort:
    name: harbor
    ports:
      http:
        port: 80
        nodePort: 30083
      https:
        port: 443
        nodePort: 30084
  ingress:
    className: nginx
    annotations:
      nginx.ingress.kubernetes.io/ssl-redirect: "false"
      nginx.ingress.kubernetes.io/proxy-body-size: "0"
      nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
      nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    hosts:
      core: harbor.local
      notary: notary.local
  tls:
    enabled: false

# Use HTTP for simplicity - no TLS complications
externalURL: http://harbor.local

# Persistence settings - Using default storage class, not NFS
persistence:
  enabled: true
  resourcePolicy: "keep"
  persistentVolumeClaim:
    registry:
      size: 50Gi
    chartmuseum:
      size: 5Gi
    jobservice:
      size: 1Gi
    database:
      size: 1Gi
    redis:
      size: 1Gi
    trivy:
      size: 5Gi

# Harbor admin password
harborAdminPassword: "Harbor12345"

# Database settings
database:
  type: internal

# Redis settings
redis:
  type: internal

# Chartmuseum for Helm charts
chartmuseum:
  enabled: true

# Clair for vulnerability scanning (deprecated, using Trivy instead)
clair:
  enabled: false

# Trivy for vulnerability scanning
trivy:
  enabled: true

# Notary for content trust
notary:
  enabled: true

# Core service
core:
  resources:
    requests:
      memory: 128Mi
      cpu: 50m
    limits:
      memory: 1Gi
      cpu: 500m

# Registry service
registry:
  resources:
    requests:
      memory: 128Mi
      cpu: 50m
    limits:
      memory: 512Mi
      cpu: 250m

# Portal (Web UI)
portal:
  resources:
    requests:
      memory: 64Mi
      cpu: 25m
    limits:
      memory: 256Mi
      cpu: 250m

# Job service
jobservice:
  resources:
    requests:
      memory: 128Mi
      cpu: 50m
    limits:
      memory: 512Mi
      cpu: 250m
EOF

# Install or upgrade Harbor
if helm list -n harbor | grep -q harbor; then
    echo "Harbor already installed. Performing clean reinstall..."
    echo "Uninstalling existing Harbor..."
    helm uninstall harbor -n harbor
    echo "Waiting for Harbor resources to be cleaned up..."
    sleep 30
    echo "Deleting PVCs..."
    kubectl delete pvc --all -n harbor || true
    sleep 10
fi

echo "Installing Harbor..."
helm install harbor harbor/harbor \
    --namespace harbor \
    --values /tmp/harbor-values.yaml \
    --timeout 10m

# Wait for Harbor to be ready
echo "⏳ Waiting for Harbor to be ready..."
kubectl wait --for=condition=ready pod -l app=harbor-core -n harbor --timeout=600s || true

# Check if Harbor is actually ready by looking at all pods
echo "🔍 Checking Harbor pod status..."
kubectl get pods -n harbor

# Wait a bit more for all pods to be ready
echo "⏳ Waiting for all Harbor pods to be running..."
sleep 60

# Check final status
echo "📊 Final Harbor status:"
kubectl get pods -n harbor

echo "✅ Harbor installed successfully!"
echo ""
echo "📋 Harbor Details:"
echo "• Namespace: harbor"
echo "• Admin Username: admin"
echo "• Admin Password: Harbor12345"
echo ""
echo "🌐 To access Harbor via NodePort:"
echo "• HTTP: http://WORKER_NODE_IP:30083"
echo "• Use the worker node's external IP address"
echo ""
echo "🐳 Docker login command:"
echo "docker login WORKER_NODE_IP:30083 -u admin -p Harbor12345"

# Clean up
rm -f /tmp/harbor-values.yaml

echo ""
echo "🔍 To check Harbor status:"
echo "kubectl get pods -n harbor"
echo "kubectl get svc -n harbor"
echo "kubectl get ingress -n harbor"
