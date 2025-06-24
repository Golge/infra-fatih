# Kubernetes Infrastructure with Terraform & Ansible

This repository contains Infrastructure as Code (IaC) for deploying a production-ready Kubernetes cluster on Google Cloud Platform using Terraform and Ansible with Kubespray.

## 🏗️ Architecture

- **Infrastructure**: 4 VMs on Google Cloud Platform
  - `master-1`, `master-2`, `master-3`: Control Plane + etcd nodes
  - `worker-1` : Worker node with applications
- **Provisioning**: Terraform for infrastructure
- **Configuration**: Ansible + Kubespray for Kubernetes
- **Applications**: Jenkins, ArgoCD, Vault, Harbor, NFS Storage

## 🚀 Quick Start

### Prerequisites
- GCloud CLI configured with project access
- Terraform/OpenTofu installed
- Python 3 with pip
- Ansible installed
- Git installed
- jq (for JSON parsing)
- SSH key pair generated (`~/.ssh/gcp_javdes`)

### Installation

#### 1. Install Prerequisites (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install -y python3 python3-pip git ansible jq

# Install terraform or tofu
# For terraform: https://developer.hashicorp.com/terraform/install
# For tofu: https://opentofu.org/docs/intro/install/
```

#### 2. Provision Infrastructure
```bash
cd ~/javdes/infra-fatih/terraform/
terraform init
terraform plan
terraform apply
```

#### 3. Test Setup (Optional)
```bash
cd ~/javdes/infra-fatih/
./test_setup.sh
```

#### 4. Install Kubernetes
```bash
cd ~/javdes/infra-fatih/
./install_kubernetes.sh
```

#### 5. Install Applications
```bash
cd ~/javdes/infra-fatih/scripts/
./install_all_apps.sh
```

## 📁 Repository Structure

```
infra-fatih/
├── terraform/          # Infrastructure provisioning
│   ├── main.tf         # Main configuration
│   ├── variables.tf    # Variables
│   ├── outputs.tf      # Outputs for Ansible
│   └── modules/        # Terraform modules
├── ansible/            # Configuration management
│   ├── inventory_dynamic.py  # Dynamic inventory
│   └── test_connectivity.yml # Tests
├── scripts/            # Application installation scripts
│   ├── install_all_apps.sh
│   ├── install_jenkins.sh
│   ├── install_harbor.sh
│   └── ...
├── docs/               # Detailed documentation
└── install_kubernetes.sh  # Main installation script
```

## 🛠️ Features

- **Infrastructure as Code**: Complete Terraform setup for GCP
- **Dynamic Inventory**: Automatic VM discovery for Ansible
- **Production Ready**: Resource limits, persistent storage, monitoring
- **CI/CD Pipeline**: Jenkins with ArgoCD for GitOps
- **Container Registry**: Harbor for image storage
- **Secrets Management**: Vault integration
- **Persistent Storage**: NFS-based storage solution

## 🔧 Services & Access

After installation, the following services will be available via NodePort:

- **Jenkins**: `http://<worker-ip>:30088`
- **ArgoCD**: `http://<worker-ip>:30081`
- **Vault**: `http://<worker-ip>:30090`
- **Harbor**: `http://<worker-ip>:30083`

## 📚 Documentation

For detailed setup instructions, troubleshooting, and advanced configuration, see [docs/README.md](docs/README.md).

## 🧹 Cleanup

```bash
cd terraform/
terraform destroy
```

## 🤝 Contributing

This project is part of the JavaDes DevOps learning initiative. Feel free to contribute improvements and suggestions.

---

**Author**: fatihgumush@gmail.com  
**Project**: JavDes Test Scenario DevOps Infrastructure
