module "gh-actions-oidc" {
  source       = "../../../modules/gcp/gh-actions-oidc"
  project      = var.project_id
  repositories = var.repositories
}

resource "google_artifact_registry_repository" "voice-assistant" {
  project       = var.project_id
  location      = "asia-northeast1"
  repository_id = "voice-assistant"
  format        = "DOCKER"
}

# VPC Network
resource "google_compute_network" "voice_assistant_network" {
  project                 = var.project_id
  name                    = "voice-assistant"
  auto_create_subnetworks = false
  mtu                     = 1460
}

# Subnet
resource "google_compute_subnetwork" "voice_assistant_subnet_1" {
  project       = var.project_id
  name          = "voice-assistant-subnet-1"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.voice_assistant_network.id
}

# Firewall rule to allow SSH
resource "google_compute_firewall" "voice_assistant_allow_ssh" {
  project = var.project_id
  name    = "voice-assistant-allow-ssh"
  network = google_compute_network.voice_assistant_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-allowed"]
}

# Firewall rule to allow HTTP/HTTPS
resource "google_compute_firewall" "voice_assistant_allow_http_https" {
  project = var.project_id
  name    = "voice-assistant-allow-http-https"
  network = google_compute_network.voice_assistant_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

# Compute Engine Instance
resource "google_compute_instance" "voice_assistant_instance_1" {
  project      = var.project_id
  name         = "voice-assistant-1"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.voice_assistant_network.id
    subnetwork = google_compute_subnetwork.voice_assistant_subnet_1.id

    access_config {
      // Ephemeral public IP for external access
      network_tier = "PREMIUM"
    }
  }

  tags = ["ssh-allowed", "web-server"]

  metadata = {}

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
  EOF

  service_account {
    scopes = ["cloud-platform"]
  }
}

# Output the external IP address
output "voice_assistant_external_ip" {
  description = "External IP address of the voice assistant instance"
  value       = google_compute_instance.voice_assistant_instance_1.network_interface[0].access_config[0].nat_ip
}

output "voice_assistant_internal_ip" {
  description = "Internal IP address of the voice assistant instance"
  value       = google_compute_instance.voice_assistant_instance_1.network_interface[0].network_ip
}
