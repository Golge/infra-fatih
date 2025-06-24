# Kubernetes Infrastructure with Terraform & Ansible

This repository contains Infrastructure as Code (IaC) for deploying a production-ready Kubernetes cluster on Google Cloud Platform using Terraform and Ansible with Kubespray.

## 🏗️ Architecture

- **Infrastructure**: 4 VMs on Google Cloud Platform
  - `master-1`, `master-2`: Control Plane + etcd nodes
  - `worker-1`, `worker-2`: Worker nodes with applications
- **Provisioning**: Terraform for infrastructure
- **Configuration**: Ansible + Kubespray for Kubernetes
- **Applications**: Jenkins, ArgoCD, Vault, Harbor, NFS Storage

## 🚀 Quick Start

### Prerequisites
- GCloud CLI configured with project access
- Terraform/OpenTofu installed
- Ansible installed
- SSH key pair generated

### 1. Provision Infrastructure
```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

### 2. Install Kubernetes
```bash
# Run the automated installation script
./install_kubernetes.sh
```

### 3. Install Applications
```bash
cd scripts/
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
**Project**: JavaDes DevOps Infrastructure
