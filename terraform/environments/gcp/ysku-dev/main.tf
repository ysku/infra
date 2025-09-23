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

# Firewall rule for WebSocket + WebRTC
resource "google_compute_firewall" "voice_assistant_allow_webrtc" {
  project = var.project_id
  name    = "voice-assistant-allow-webrtc"
  network = google_compute_network.voice_assistant_network.name

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }

  allow {
    protocol = "udp"
    ports    = ["10000-20000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["webrtc-server"]
}

# Firewall rule for TURN server
resource "google_compute_firewall" "voice_assistant_allow_turn" {
  project = var.project_id
  name    = "voice-assistant-allow-turn"
  network = google_compute_network.voice_assistant_network.name

  allow {
    protocol = "tcp"
    ports    = ["3478", "5349"]
  }

  allow {
    protocol = "udp"
    ports    = ["3478", "49152-65535"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["turn-server"]
}

# Firewall rule for Twilio WebRTC
resource "google_compute_firewall" "voice_assistant_allow_twilio" {
  project = var.project_id
  name    = "voice-assistant-allow-twilio"
  network = google_compute_network.voice_assistant_network.name

  allow {
    protocol = "udp"
    ports    = ["3478", "10000-60000"]
  }

  allow {
    protocol = "tcp"
    ports    = ["3478", "5349"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["twilio-webrtc"]
}

# Static external IP address
resource "google_compute_address" "voice_assistant_static_ip" {
  project = var.project_id
  name    = "voice-assistant-static-ip"
  region  = var.region
}

# Compute Engine Instance
resource "google_compute_instance" "voice_assistant_instance_1" {
  project      = var.project_id
  name         = "voice-assistant-1"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.voice_assistant_network.id
    subnetwork = google_compute_subnetwork.voice_assistant_subnet_1.id

    access_config {
      // Static public IP for external access
      nat_ip       = google_compute_address.voice_assistant_static_ip.address
      network_tier = "PREMIUM"
    }
  }

  tags = ["ssh-allowed", "web-server", "webrtc-server", "turn-server", "twilio-webrtc"]

  metadata = {}

  # check logs by tail -f /var/log/syslog
  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Update package index
    apt-get update

    # Install prerequisites
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker's official GPG key
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update package index with Docker repo
    apt-get update

    # Install Docker Engine
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Start and enable Docker service
    systemctl start docker
    systemctl enable docker

    # Add ubuntu user to docker group
    usermod -aG docker ubuntu

    # Install nginx for web server (optional)
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx

    # Install certbot for SSL certificates
    apt-get install -y snapd
    snap install core; snap refresh core
    snap install --classic certbot

    # Create symlink for certbot command
    ln -s /snap/bin/certbot /usr/bin/certbot
  EOF

  service_account {
    scopes = ["cloud-platform"]
  }
}

# Output the static external IP address
output "voice_assistant_external_ip" {
  description = "Static external IP address of the voice assistant instance"
  value       = google_compute_address.voice_assistant_static_ip.address
}

output "voice_assistant_internal_ip" {
  description = "Internal IP address of the voice assistant instance"
  value       = google_compute_instance.voice_assistant_instance_1.network_interface[0].network_ip
}
