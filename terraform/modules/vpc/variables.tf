variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "javdes-network"
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "javdes-subnet"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.240.0.0/24"
}

variable "region" {
  description = "GCP region for the subnet"
  type        = string
  default     = "europe-west4"
}
