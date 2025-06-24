output "vm_names" {
  description = "Names of the provisioned VMs."
  value       = var.vm_names
}

output "vm_instance_self_links" {
  description = "Self-links of the provisioned VMs."
  value       = [for instance in google_compute_instance.vm : instance.self_link]
}

output "vm_instance_ips" {
  description = "Internal IPs of the provisioned VMs."
  value       = { for name, instance in google_compute_instance.vm : name => instance.network_interface[0].network_ip }
}

output "vm_instance_external_ips" {
  description = "External IPs of the provisioned VMs."
  value       = { for name, instance in google_compute_instance.vm : name => try(instance.network_interface[0].access_config[0].nat_ip, null) }
}

output "vm_instance_labels" {
  description = "Labels of the provisioned VMs."
  value       = { for name, instance in google_compute_instance.vm : name => instance.labels }
}