#!/bin/bash

# Quick NFS Fix - Run this script on each node via SSH
# This should be run from your local machine

set -e

echo "🚀 Quick NFS Fix for all nodes..."

# Define your nodes (update with your actual IPs)
MASTER_IPS=("34.91.39.156" "35.204.211.98" "34.13.229.179")
WORKER_IPS=("34.91.71.244")
SSH_KEY="~/.ssh/gcp_javdes"
USER="fatihgumush"

# Function to install NFS client on a node
install_nfs_client() {
    local ip=$1
    local node_type=$2
    
    echo "📦 Installing NFS client on $node_type ($ip)..."
    ssh -i $SSH_KEY -o StrictHostKeyChecking=no $USER@$ip "
        sudo apt-get update
        sudo apt-get install -y nfs-common
        sudo systemctl enable rpc-statd
        sudo systemctl start rpc-statd
        echo 'NFS client installed on $node_type'
    " || echo "⚠️ Failed to install NFS client on $ip"
}

# Function to setup NFS server on worker
setup_nfs_server_worker() {
    local ip=$1
    echo "🔧 Setting up NFS server on worker ($ip)..."
    ssh -i $SSH_KEY -o StrictHostKeyChecking=no $USER@$ip "
        sudo apt-get update
        sudo apt-get install -y nfs-kernel-server nfs-common
        sudo mkdir -p /nfs/data
        sudo chmod 777 /nfs/data
        sudo chown nobody:nogroup /nfs/data
        echo '/nfs/data *(rw,sync,no_subtree_check,no_root_squash,insecure)' | sudo tee /etc/exports
        sudo systemctl enable nfs-kernel-server
        sudo systemctl restart nfs-kernel-server
        sudo exportfs -ra
        sudo exportfs -v
        sudo systemctl status nfs-kernel-server --no-pager
        echo 'NFS server setup completed on worker'
    " || echo "⚠️ Failed to setup NFS server on $ip"
}

# Setup NFS server on all worker nodes
for ip in "${WORKER_IPS[@]}"; do
    setup_nfs_server_worker $ip
    install_nfs_client $ip "worker"
done

# Install NFS client on all master nodes
for ip in "${MASTER_IPS[@]}"; do
    install_nfs_client $ip "master"
done

echo "✅ NFS setup completed on all nodes!"
echo ""
echo "Now restart the NFS provisioner pod if needed:"
echo "kubectl delete pod -n nfs-provisioner -l app=nfs-subdir-external-provisioner"
