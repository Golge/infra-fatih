resource "google_service_account" "default" {
  account_id   = "javdes-sa"
  display_name = "SA for VM Instance"
}

resource "google_compute_instance" "vm" {
  for_each     = toset(var.vm_names)
  project      = var.project
  name         = each.value
  machine_type = each.value == "worker-1" ? "e2-standard-4" : "e2-small"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 100
    }
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.subnet_name
    access_config {}
  }

  service_account {
    email  = google_service_account.default.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = "fatihgumush:${file(var.public_key_path)}"
  }

  labels = {
    role = contains(["master-1", "master-2", "master-3"], each.value) ? "master" : "worker"
  }

  tags = ["kubernetes"]
}
