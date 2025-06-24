resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id

#   secondary_ip_range {
#     range_name    = "k8s-pod-range"
#     ip_cidr_range = "10.200.0.0/16"
#   }

#   secondary_ip_range {
#     range_name    = "k8s-service-range"
#     ip_cidr_range = "10.32.0.0/24"
#   }
}

# Internal firewall rule
resource "google_compute_firewall" "kubernetes_allow_internal" {
  name    = "kubernetes-allow-internal"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "ah"
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["kubernetes"]
}

# External firewall rule
resource "google_compute_firewall" "kubernetes_allow_external" {
  name    = "kubernetes-allow-external"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "6443", "443", "22"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["kubernetes"]
}

# NodePort firewall rule for Kubernetes services
resource "google_compute_firewall" "kubernetes_allow_nodeport" {
  name    = "kubernetes-allow-nodeport"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["kubernetes"]
  
  description = "Allow NodePort access for Kubernetes services (Jenkins, ArgoCD, Vault, Harbor, etc.)"
}
