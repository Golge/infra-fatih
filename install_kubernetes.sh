#!/bin/bash

set -e

echo "🚀 Installing Kubernetes with Kubespray"
echo "========================================"

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check if required tools are installed
missing_tools=()

if ! command -v python3 &> /dev/null; then
    missing_tools+=("python3")
fi

if ! command -v pip &> /dev/null && ! command -v pip3 &> /dev/null; then
    missing_tools+=("pip/pip3")
fi

if ! command -v git &> /dev/null; then
    missing_tools+=("git")
fi

if [ ${#missing_tools[@]} -ne 0 ]; then
    echo "❌ Missing required tools: ${missing_tools[*]}"
    echo "Please install them first:"
    echo "  sudo apt update"
    echo "  sudo apt install -y python3 python3-pip git ansible jq"
    exit 1
fi

echo "✅ All required tools are installed"

# Ensure we're in the project root
cd ~/javdes

# Setup Kubespray if it doesn't exist
if [ ! -d ~/javdes/kubespray ]; then
    echo "📦 Setting up Kubespray..."
    cd ~/javdes
    git clone https://github.com/kubernetes-sigs/kubespray.git
    cd kubespray
    
    # Create and activate virtual environment
    echo "🔧 Creating kubespray virtual environment..."
    python3 -m venv kubespray-venv
    source kubespray-venv/bin/activate
    
    # Install requirements
    echo "📦 Installing Kubespray requirements..."
    pip install -U pip
    pip install -r requirements.txt
    
else
    echo "✅ Kubespray already exists"
fi

# Activate kubespray virtual environment
echo "🔧 Activating kubespray virtual environment..."
source ~/javdes/kubespray/kubespray-venv/bin/activate

# Verify terraform infrastructure exists
echo "🔍 Verifying terraform infrastructure..."
cd ~/javdes/infra-fatih/terraform
if [ ! -f "terraform.tfstate" ]; then
    echo "❌ No terraform state found! Please run 'terraform apply' first."
    echo "   cd ~/javdes/infra-fatih/terraform/ && terraform init && terraform apply"
    exit 1
fi

# Check if we can get terraform output
if command -v tofu &> /dev/null; then
    TF_CMD="tofu"
elif command -v terraform &> /dev/null; then
    TF_CMD="terraform"
else
    echo "❌ Neither terraform nor tofu found. Please install one of them."
    exit 1
fi

echo "✅ Using $TF_CMD command"
$TF_CMD output -json > /tmp/tf_output.json
if [ $? -ne 0 ]; then
    echo "❌ Cannot get terraform output. Infrastructure may not be deployed."
    echo "   Run: cd ~/javdes/infra-fatih/terraform/ && $TF_CMD apply"
    exit 1
fi

echo "✅ Infrastructure verified"

# Test connectivity first
echo "🔍 Testing connectivity to all hosts..."
cd ~/javdes/infra-fatih/ansible

# Make inventory script executable
chmod +x inventory_dynamic.py

# Test the inventory script
echo "🔍 Testing inventory script..."
python3 inventory_dynamic.py --list > /tmp/inventory_check.json
if [ $? -eq 0 ]; then
    echo "✅ Inventory script working correctly"
    echo "📋 Found hosts:"
    jq -r '.all.hosts[]' /tmp/inventory_check.json
else
    echo "❌ Inventory script failed. Check terraform output."
    exit 1
fi

# Test connectivity
ansible all -i inventory_dynamic.py -m ping

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

cd ~/javdes/kubespray

# Run the cluster installation
ansible-playbook -i ../infra-fatih/ansible/inventory_dynamic.py -b cluster.yml

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Kubernetes installation complete!"
    echo ""
    echo "Next steps:"
    echo "1. Get master IP address:"
    echo "   cd ~/javdes/infra-fatih/terraform && $TF_CMD output vm_instance_external_ips"
    echo ""
    echo "2. SSH to master-1 (replace <MASTER_1_IP> with actual IP):"
    echo "   ssh -i ~/.ssh/gcp_javdes fatihgumush@<MASTER_1_IP>"
    echo ""
    echo "3. Copy kubeconfig on master-1:"
    echo "   mkdir -p ~/.kube && sudo cp /etc/kubernetes/admin.conf ~/.kube/config && sudo chown \$(id -u):\$(id -g) ~/.kube/config"
    echo ""
    echo "4. Test cluster:"
    echo "   kubectl get nodes"
    echo ""
    echo "5. Install applications:"
    echo "   cd ~/javdes/infra-fatih/scripts && ./install_all_apps.sh"
    echo ""
    echo "Your Kubernetes cluster is now ready! 🚀"
else
    echo ""
    echo "❌ Kubernetes installation failed. Check the logs above for details."
    echo ""
    echo "Common issues:"
    echo "- SSH connectivity: Check if you can SSH to all VMs"
    echo "- Inventory: Run 'python3 ~/javdes/infra-fatih/ansible/inventory_dynamic.py --list'"
    echo "- Terraform: Ensure 'terraform apply' was successful"
    echo ""
    exit 1
fi
