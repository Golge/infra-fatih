output "vm_names" {
  description = "Names of the provisioned VMs."
  value       = module.vm.vm_names
}

output "vm_instance_external_ips" {
  description = "External IPs of the provisioned VMs."
  value       = module.vm.vm_instance_external_ips
}

output "vm_instance_internal_ips" {
  description = "Internal IPs of the provisioned VMs."
  value       = module.vm.vm_instance_ips
}

output "vm_instance_labels" {
  description = "Labels of the provisioned VMs."
  value       = module.vm.vm_instance_labels
}