#!/bin/bash

# Master Installation Script
# This script can install all applications or individual ones

set -e

echo "🚀 Kubernetes Applications Installer"
echo "===================================="
echo ""

# Function to display usage
usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  all                     Install all applications"
    echo "  cert-manager            Install Cert-Manager"
    echo "  jenkins                 Install Jenkins"
    echo "  vault                   Install HashiCorp Vault"
    echo "  argocd                  Install ArgoCD"
    echo "  external-secrets        Install External Secrets Operator"
    echo "  harbor                  Install Harbor Registry"
    echo "  help                    Show this help message"
    echo ""
    echo "Individual application scripts are also available:"
    echo "  ./install_cert_manager.sh"
    echo "  ./install_jenkins.sh"
    echo "  ./install_vault.sh"
    echo "  ./install_argocd.sh"
    echo "  ./install_external_secrets.sh"
    echo "  ./install_harbor.sh"
    echo ""
    echo "Prerequisites:"
    echo "  - kubectl configured and connected to cluster"
    echo "  - helm installed"
    echo "  - NFS storage class available (nfs-client) - run ./1_install_nfs_storage.sh first"
    echo "  - NGINX Ingress Controller installed"
}

# Function to check prerequisites
check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl not found. Please install kubectl first."
        exit 1
    fi
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        echo "❌ Helm not found. Please install Helm first."
        exit 1
    fi
    
    # Check cluster connection
    if ! kubectl cluster-info &> /dev/null; then
        echo "❌ Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    # Check NFS storage class
    if ! kubectl get storageclass nfs-client &> /dev/null; then
        echo "⚠️  Warning: NFS storage class 'nfs-client' not found."
        echo "   Some applications may not work properly without persistent storage."
        echo "   Run ./1_install_nfs_storage.sh first if needed."
    fi
    
    # Check NGINX Ingress
    if ! kubectl get pods -n ingress-nginx | grep -q ingress-nginx-controller; then
        echo "⚠️  Warning: NGINX Ingress Controller not found."
        echo "   Ingress resources will not work properly."
        echo "   Run ./install_nginx_ingress.sh first if needed."
    fi
    
    echo "✅ Prerequisites check completed!"
    echo ""
}

# Function to install individual application
install_app() {
    local app=$1
    local script_name="install_${app}.sh"
    
    if [ -f "./$script_name" ]; then
        echo "🚀 Installing $app..."
        ./$script_name
        echo ""
    else
        echo "❌ Script $script_name not found!"
        exit 1
    fi
}

# Main script logic
case "${1:-help}" in
    "all")
        check_prerequisites
        echo "📦 Installing all applications..."
        echo ""
        install_app "cert_manager"
        install_app "jenkins"
        install_app "vault"
        install_app "argocd"
        install_app "external_secrets"
        install_app "harbor"
        echo "🎉 All applications installed successfully!"
        echo ""
        echo "📋 Summary of installed applications:"
        echo "• Cert-Manager: cert-manager namespace"
        echo "• Jenkins: jenkins namespace"
        echo "• HashiCorp Vault: vault namespace"
        echo "• ArgoCD: argocd namespace"
        echo "• External Secrets Operator: external-secrets namespace"
        echo "• Harbor Registry: harbor namespace"
        echo ""
        echo "🌐 Access URLs (add to /etc/hosts or use NodePort):"
        echo "• Jenkins: http://jenkins.local"
        echo "• ArgoCD: http://argocd.local"
        echo "• Vault: http://vault.local"
        echo "• Harbor: https://harbor.local"
        echo ""
        echo "💡 Run ./setup_service_access.sh for detailed access instructions"
        ;;
    "cert-manager")
        check_prerequisites
        install_app "cert_manager"
        ;;
    "jenkins")
        check_prerequisites
        install_app "jenkins"
        ;;
    "vault")
        check_prerequisites
        install_app "vault"
        ;;
    "argocd")
        check_prerequisites
        install_app "argocd"
        ;;
    "external-secrets")
        check_prerequisites
        install_app "external_secrets"
        ;;
    "harbor")
        check_prerequisites
        install_app "harbor"
        ;;
    "help"|*)
        usage
        ;;
esac
