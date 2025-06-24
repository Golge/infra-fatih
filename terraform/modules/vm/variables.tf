# GCP project ID
variable "project" {
  description = "GCP project ID"
  type        = string
  default     = "javdes"
}

variable "region" {
  description = "GCP region to deploy resources in."
  type        = string
  default     = "europe-west4"
}

variable "zone" {
  description = "GCP zone to deploy resources in."
  type        = string
  default     = "europe-west4-a"
}

variable "vm_names" {
  description = "List of VM names to create."
  type        = list(string)
  default     = ["master-1", "master-2", "master-3", "worker-1"]
}

variable "public_key_path" {
  description = "Path to the SSH public key to add to VM instances."
  type        = string
  default     = "~/.ssh/gcp_javdes.pub"
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}
