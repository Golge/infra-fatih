#!/bin/bash

# Service Access Configuration Script
# This script helps configure access to Kubernetes services via NodePort and local hosts file

set -e

echo "🌐 Kubernetes Services Access Configuration"
echo "==========================================="
echo ""

# Get node external IPs
echo "🔍 Getting node external IPs..."
NODE_IPS=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')
EXTERNAL_IPS="34.91.39.156 35.204.211.98 34.13.229.179 34.91.71.244"

# We'll use the first master node as the primary access point
PRIMARY_NODE_IP="34.91.39.156"  # master-1 external IP

echo "📋 Available Node External IPs:"
echo "• master-1: 34.91.39.156"
echo "• master-2: 35.204.211.98"
echo "• master-3: 34.13.229.179"
echo "• worker-1: 34.91.71.244"
echo ""

# Get NodePort information
echo "🔍 Getting Service NodePorts..."
NGINX_HTTP_NODEPORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}' 2>/dev/null || echo "N/A")
NGINX_HTTPS_NODEPORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}' 2>/dev/null || echo "N/A")

# Get individual service NodePorts
JENKINS_NODEPORT=$(kubectl get svc -n jenkins jenkins -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30088")
ARGOCD_NODEPORT=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}' 2>/dev/null || echo "30081")
VAULT_NODEPORT=$(kubectl get svc -n vault vault -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30090")
HARBOR_HTTP_NODEPORT=$(kubectl get svc -n harbor harbor -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}' 2>/dev/null || echo "30083")
HARBOR_HTTPS_NODEPORT=$(kubectl get svc -n harbor harbor -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}' 2>/dev/null || echo "30084")

echo "📋 Service NodePorts:"
echo "• Jenkins: $JENKINS_NODEPORT"
echo "• ArgoCD: $ARGOCD_NODEPORT"
echo "• Vault: $VAULT_NODEPORT"
echo "• Harbor HTTP: $HARBOR_HTTP_NODEPORT"
echo "• Harbor HTTPS: $HARBOR_HTTPS_NODEPORT"
if [ "$NGINX_HTTP_NODEPORT" != "N/A" ]; then
    echo "• NGINX Ingress HTTP: $NGINX_HTTP_NODEPORT"
    echo "• NGINX Ingress HTTPS: $NGINX_HTTPS_NODEPORT"
fi
echo ""

# Create hosts file entries (optional - for friendly names)
echo "📝 Creating optional hosts file entries..."
cat > /tmp/hosts_entries.txt << EOF
# Kubernetes Services Access (Optional - for friendly names)
# Add these entries to your /etc/hosts file (Linux/Mac) or C:\Windows\System32\drivers\etc\hosts (Windows)
# Note: You can also access directly via IP:NodePort without these entries

$PRIMARY_NODE_IP harbor.local
$PRIMARY_NODE_IP jenkins.local
$PRIMARY_NODE_IP argocd.local
$PRIMARY_NODE_IP vault.local
EOF

echo "✅ Hosts file entries created!"
echo ""
echo "📋 Service Access Information:"
echo "============================================="
echo ""
echo "🐳 Harbor Registry:"
echo "• HTTP URL: http://34.91.71.244:$HARBOR_HTTP_NODEPORT (Recommended - HTTP only)"
echo "• Username: admin"
echo "• Password: Harbor12345"
echo "• Docker login: docker login 34.91.71.244:$HARBOR_HTTP_NODEPORT -u admin -p Harbor12345"
echo ""
echo "🏗️ Jenkins:"
echo "• URL: http://$PRIMARY_NODE_IP:$JENKINS_NODEPORT"
echo "• Username: admin"
echo "• Password: (run: kubectl get secret --namespace jenkins jenkins -o jsonpath=\"{.data.jenkins-admin-password}\" | base64 --decode)"
echo ""
echo "🚀 ArgoCD:"
echo "• URL: http://$PRIMARY_NODE_IP:$ARGOCD_NODEPORT"
echo "• Username: admin"
echo "• Password: (run: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d)"
echo ""
echo "🔒 Vault:"
echo "• URL: http://$PRIMARY_NODE_IP:$VAULT_NODEPORT"
echo "• Root Token: root (development mode)"
echo ""
echo "📝 Setup Instructions:"
echo "======================"
echo ""
echo "1. Direct NodePort Access (Recommended - No hosts file needed):"
echo "   • Harbor: http://34.91.71.244:$HARBOR_HTTP_NODEPORT (HTTP only)"
echo "   • Jenkins: http://$PRIMARY_NODE_IP:$JENKINS_NODEPORT"
echo "   • ArgoCD: http://$PRIMARY_NODE_IP:$ARGOCD_NODEPORT"
echo "   • Vault: http://$PRIMARY_NODE_IP:$VAULT_NODEPORT"
echo ""
echo "2. Alternative: Use any node IP (all nodes route to the same services):"
echo "   • master-1: 35.204.211.98"
echo "   • master-2: 34.13.229.179"
echo "   • master-3: 34.91.39.156"
echo "   • worker-1: 34.91.71.244"
echo ""
echo "3. Optional: Add hosts file entries for friendly names:"
echo "   Linux/Mac: sudo tee -a /etc/hosts < /tmp/hosts_entries.txt"
echo "   Windows: Add entries to C:\Windows\System32\drivers\etc\hosts"
echo ""
echo "4. For HTTPS services (like Harbor), you may need to:"
echo "   • Accept the self-signed certificate warning in your browser"
echo "   • Or add certificate exception"
echo ""
echo "4. Test connectivity:"
echo "   curl http://34.91.71.244:$HARBOR_HTTP_NODEPORT"
echo "   curl http://$PRIMARY_NODE_IP:$JENKINS_NODEPORT"
echo "   curl http://$PRIMARY_NODE_IP:$ARGOCD_NODEPORT"
echo "   curl http://$PRIMARY_NODE_IP:$VAULT_NODEPORT"
echo ""

# Display the hosts file entries
echo "📋 Copy these entries to your hosts file:"
echo "=========================================="
cat /tmp/hosts_entries.txt
echo ""

# Create a quick access script
cat > /tmp/quick_access.sh << 'EOF'
#!/bin/bash
echo "🚀 Quick Service Access"
echo "======================"
echo ""
echo "🔑 Getting service passwords..."
echo ""
echo "Jenkins Admin Password:"
kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
echo ""
echo ""
echo "ArgoCD Admin Password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "ArgoCD not installed or secret not found"
echo ""
echo ""
echo "Vault Root Token:"
echo "Check your Vault installation output for the root token"
echo ""
EOF

chmod +x /tmp/quick_access.sh

echo "🎯 Quick access script created at /tmp/quick_access.sh"
echo "Run: /tmp/quick_access.sh to get service passwords"
echo ""

# Test connectivity
echo "🧪 Testing connectivity to services..."
echo "Testing Harbor (HTTPS):"
curl -k -I https://$PRIMARY_NODE_IP:$HARBOR_HTTPS_NODEPORT 2>/dev/null | head -1 || echo "Harbor HTTPS not accessible"

echo "Testing Harbor (HTTP):"
curl -I http://$PRIMARY_NODE_IP:$HARBOR_HTTP_NODEPORT 2>/dev/null | head -1 || echo "Harbor HTTP not accessible"

echo "Testing Jenkins:"
curl -I http://$PRIMARY_NODE_IP:$JENKINS_NODEPORT 2>/dev/null | head -1 || echo "Jenkins not accessible"

echo "Testing ArgoCD:"
curl -I http://$PRIMARY_NODE_IP:$ARGOCD_NODEPORT 2>/dev/null | head -1 || echo "ArgoCD not accessible"

echo "Testing Vault:"
curl -I http://$PRIMARY_NODE_IP:$VAULT_NODEPORT 2>/dev/null | head -1 || echo "Vault not accessible"

echo ""
echo "✅ Configuration complete!"
echo ""
echo "💡 Pro Tips:"
echo "• All services are now accessible via dedicated NodePorts on any node IP"
echo "• No hosts file configuration required - access directly via IP:Port"
echo "• Use HTTPS for Harbor (port $HARBOR_HTTPS_NODEPORT) for secure registry access"
echo "• Use HTTP for other services (Jenkins: $JENKINS_NODEPORT, ArgoCD: $ARGOCD_NODEPORT, Vault: $VAULT_NODEPORT)"
echo "• For production, consider using a LoadBalancer or proper DNS setup"
