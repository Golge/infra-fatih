# Kubernetes Cluster Resource Allocation

## Infrastructure
- **Master Nodes (3)**: e2-medium (1 vCPU, 4GB RAM each)
- **Worker Node (1)**: e2-standard-4 (4 vCPU, 16GB RAM)
- **Total Worker Resources**: 4 vCPU, 16GB RAM

## Application Resource Allocation

### Jenkins
- **Requests**: 200m CPU, 1GB RAM
- **Limits**: 1 CPU, 3GB RAM
- **Purpose**: CI/CD pipeline execution

### Harbor Registry
- **Core**: 50m CPU, 128MB RAM (limits: 500m CPU, 1GB RAM)
- **Registry**: 50m CPU, 128MB RAM (limits: 250m CPU, 512MB RAM)
- **Portal**: 25m CPU, 64MB RAM (limits: 250m CPU, 256MB RAM)
- **JobService**: 50m CPU, 128MB RAM (limits: 250m CPU, 512MB RAM)
- **Database**: Default (PostgreSQL)
- **Redis**: Default
- **Trivy**: Default (vulnerability scanning)

### ArgoCD
- **Server**: 50m CPU, 128MB RAM (limits: 500m CPU, 512MB RAM)
- **Repo Server**: 50m CPU, 128MB RAM (limits: 250m CPU, 512MB RAM)
- **Controller**: 100m CPU, 256MB RAM (limits: 500m CPU, 1GB RAM)
- **Dex**: 25m CPU, 64MB RAM (limits: 250m CPU, 256MB RAM)

### HashiCorp Vault
- **Server**: 50m CPU, 128MB RAM (limits: 250m CPU, 512MB RAM)
- **Mode**: Development mode with root token

### External Secrets Operator
- **Controller**: 25m CPU, 64MB RAM (limits: 250m CPU, 256MB RAM)
- **Webhook**: 25m CPU, 64MB RAM (limits: 250m CPU, 256MB RAM)
- **Cert Controller**: 25m CPU, 64MB RAM (limits: 250m CPU, 256MB RAM)

## Total Resource Requirements

### CPU Requests (minimum needed)
- Jenkins: 200m
- Harbor: ~175m (all components)
- ArgoCD: ~225m (all components)
- Vault: 50m
- External Secrets: 75m
- **Total**: ~725m (~0.7 CPU cores)

### Memory Requests (minimum needed)
- Jenkins: 1GB
- Harbor: ~448MB (all components)
- ArgoCD: ~576MB (all components)
- Vault: 128MB
- External Secrets: 192MB
- **Total**: ~2.3GB

### CPU Limits (maximum allowed)
- Jenkins: 1 CPU
- Harbor: ~1.25 CPU (all components)
- ArgoCD: ~1.5 CPU (all components)
- Vault: 250m
- External Secrets: 750m
- **Total**: ~4.75 CPU (may burst beyond available)

### Memory Limits (maximum allowed)
- Jenkins: 3GB
- Harbor: ~2.3GB (all components)
- ArgoCD: ~2.3GB (all components)
- Vault: 512MB
- External Secrets: 768MB
- **Total**: ~8.9GB

## Resource Utilization Summary
- **Available Worker Resources**: 4 vCPU, 16GB RAM
- **Minimum Required**: 0.7 vCPU, 2.3GB RAM
- **Maximum Burst**: 4.75 vCPU, 8.9GB RAM
- **Safety Margin**: Good - plenty of headroom for application workloads

## Recommendations
1. Monitor actual resource usage after deployment
2. Adjust limits based on real usage patterns
3. Consider horizontal pod autoscaling for Jenkins agents if needed
4. Reserve ~25% of resources for system pods and overhead
5. The current configuration leaves ~7GB RAM for your application workloads

## Notes
- All applications use NFS storage for persistence
- Resource limits prevent any single application from consuming all resources
- Kubernetes scheduler will ensure pods fit within available node resources
- Some components (like Harbor database, Redis, Trivy) use default resources which are typically minimal
