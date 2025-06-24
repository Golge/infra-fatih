#!/usr/bin/env python3
import json
import subprocess
import sys
import os

# Get terraform/tofu output as JSON
def get_terraform_output():
    # Change to terraform directory
    terraform_dir = os.path.join(os.path.dirname(__file__), "..", "terraform")
    
    # Try tofu first, then terraform
    for cmd in ["tofu", "terraform"]:
        try:
            result = subprocess.run([
                cmd, "output", "-json"
            ], cwd=terraform_dir, capture_output=True, text=True)
            
            if result.returncode == 0:
                return json.loads(result.stdout)
            else:
                print(f"Command '{cmd}' failed with return code {result.returncode}", file=sys.stderr)
                print(f"Error: {result.stderr}", file=sys.stderr)
        except FileNotFoundError:
            print(f"Command '{cmd}' not found", file=sys.stderr)
            continue
    
    print("Neither 'tofu' nor 'terraform' command found or working", file=sys.stderr)
    sys.exit(1)

def main():
    tf = get_terraform_output()
    
    # Extract values from terraform output
    vm_names = tf["vm_names"]["value"]
    external_ips = tf["vm_instance_external_ips"]["value"]
    internal_ips = tf["vm_instance_internal_ips"]["value"]  # Use internal IPs
    labels = tf["vm_instance_labels"]["value"]
    
    # Build inventory in Ansible dynamic inventory format
    inventory = {
        "_meta": {
            "hostvars": {}
        }
    }
    
    # Initialize groups
    inventory["all"] = {"hosts": []}
    inventory["kube_control_plane"] = {"hosts": []}
    inventory["etcd"] = {"hosts": []}
    inventory["kube_node"] = {"hosts": []}
    inventory["k8s_cluster"] = {"children": ["kube_control_plane", "kube_node"]}
    
    # Process each VM
    for vm_name in vm_names:
        external_ip = external_ips.get(vm_name)
        internal_ip = internal_ips.get(vm_name)  # Get internal IP
        if not external_ip or not internal_ip:
            continue
            
        # Add to all hosts list
        inventory["all"]["hosts"].append(vm_name)
        
        # Set host variables - use external IP for SSH, internal IP for Kubernetes
        inventory["_meta"]["hostvars"][vm_name] = {
            "ansible_host": external_ip,  # SSH connection
            "ip": internal_ip,            # Kubernetes internal communication
            "access_ip": internal_ip,     # Access IP for Kubernetes
            "ansible_user": "fatihgumush",
            "ansible_ssh_private_key_file": "~/.ssh/gcp_javdes"
        }
        
        # Get role from labels and add to appropriate groups
        vm_labels = labels.get(vm_name, {})
        role = vm_labels.get("role", "worker")
        
        if role == "master":
            inventory["kube_control_plane"]["hosts"].append(vm_name)
            # Use all 3 masters for etcd (odd number for proper quorum)
            inventory["etcd"]["hosts"].append(vm_name)
        else:
            inventory["kube_node"]["hosts"].append(vm_name)
    
    print(json.dumps(inventory, indent=2))

if __name__ == "__main__":
    main()
