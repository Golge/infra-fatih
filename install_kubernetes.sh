#!/bin/bash

set -e

echo "🚀 Installing Kubernetes with Kubespray"
echo "========================================"

# Ensure we're in the project root
cd /home/golge/javdes

# Activate kubespray virtual environment
echo "🔧 Activating kubespray virtual environment..."
source kubespray-venv/bin/activate

# Test connectivity first
echo "🔍 Testing connectivity to all hosts..."
cd infra-fatih/ansible
ansible all -m ping

if [ $? -eq 0 ]; then
    echo "✅ All hosts are reachable"
else
    echo "❌ Some hosts are not reachable. Check SSH connectivity."
    exit 1
fi

# Run Kubespray from the kubespray directory
echo ""
echo "☸️  Starting Kubernetes installation..."
echo "This may take 15-30 minutes..."
echo ""
echo "Configuration:"
echo "- 3 Control Plane Nodes: master-1, master-2, master-3"
echo "- 3 etcd Nodes: master-1, master-2, master-3 (proper quorum)"
echo "- 1 Worker Node: worker-1"
echo "- Network: 10.240.0.0/24"
echo ""

cd /home/golge/javdes/kubespray

# Run the cluster installation
ansible-playbook -i ../infra-fatih/ansible/inventory_dynamic.py -b cluster.yml

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Kubernetes installation complete!"
    echo ""
    echo "Next steps:"
    echo "1. SSH to master-1: ssh -i ~/.ssh/gcp_javdes fatihgumush@<MASTER_1_IP>"
    echo "2. Copy kubeconfig: mkdir -p ~/.kube && sudo cp /etc/kubernetes/admin.conf ~/.kube/config && sudo chown \$(id -u):\$(id -g) ~/.kube/config"
    echo "3. Test cluster: kubectl get nodes"
    echo ""
    echo "Your Kubernetes cluster is now ready! 🚀"
else
    echo ""
    echo "❌ Kubernetes installation failed. Check the logs above for details."
    exit 1
fi
