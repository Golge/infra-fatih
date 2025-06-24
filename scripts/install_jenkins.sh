#!/bin/bash

# Jenkins Installation
# This script installs Jenkins using Helm

set -e

echo "🏗️ Installing Jenkins..."

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

# Add Jenkins Helm repository
echo "📚 Adding Jenkins Helm repository..."
helm repo add jenkins https://charts.jenkins.io
helm repo update

# Create namespace for Jenkins
echo "🏗️ Creating jenkins namespace..."
kubectl create namespace jenkins || echo "Namespace already exists"

# Create Jenkins values file
echo "📝 Creating Jenkins configuration..."
cat > /tmp/jenkins-values.yaml <<EOF
controller:
  serviceType: NodePort
  nodePort: 30088
  installPlugins:
    - kubernetes:latest
    - workflow-aggregator:latest
    - git:latest
    - configuration-as-code:latest
    - blueocean:latest
    - docker-workflow:latest
    - sonar:latest
    - pipeline-stage-view:latest
    - build-timeout:latest
    - credentials-binding:latest
  resources:
    requests:
      cpu: "200m"
      memory: "1Gi"
    limits:
      cpu: "1"
      memory: "3Gi"
  persistence:
    enabled: true
    size: "20Gi"
    storageClass: "nfs-client"
  ingress:
    enabled: true
    hostName: jenkins.local
    annotations:
      nginx.ingress.kubernetes.io/rewrite-target: /
    ingressClassName: nginx
agent:
  enabled: false
serviceAccount:
  create: true
  name: jenkins
  annotations: {}
rbac:
  create: true
  readSecrets: true
EOF

# Install or upgrade Jenkins
if helm list -n jenkins | grep -q jenkins; then
    echo "Jenkins already installed, upgrading..."
    helm upgrade jenkins jenkins/jenkins \
        --namespace jenkins \
        --values /tmp/jenkins-values.yaml
else
    echo "Installing Jenkins..."
    helm install jenkins jenkins/jenkins \
        --namespace jenkins \
        --values /tmp/jenkins-values.yaml
fi

# Wait for Jenkins to be ready
echo "⏳ Waiting for Jenkins to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=jenkins-controller -n jenkins --timeout=600s

echo "✅ Jenkins installed successfully!"
echo ""
echo "📋 Jenkins Details:"
echo "• Namespace: jenkins"
echo "• Access URL: http://jenkins.local (add to /etc/hosts)"
echo "• Admin Username: admin"

echo ""
echo "🔑 Jenkins admin password:"
kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
echo ""

echo ""
echo "🌐 To access Jenkins:"
echo "1. Get the NodePort:"
echo "   kubectl get svc -n jenkins jenkins"
echo "2. Access via: http://<node-ip>:<nodeport>"
echo "3. Or add jenkins.local to /etc/hosts and use ingress"

# Clean up
rm -f /tmp/jenkins-values.yaml

echo ""
echo "🔍 To check Jenkins status:"
echo "kubectl get pods -n jenkins"
echo "kubectl get svc -n jenkins"
