# VPC Network
resource "google_compute_network" "shared_vpc" {
  project                 = var.project_id
  name                    = "shared-vpc"
  auto_create_subnetworks = false
  description             = "Shared VPC for all projects in ysku-dev"
}

# Enable required APIs
resource "google_project_service" "container_api" {
  project = var.project_id
  service = "container.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"

  disable_on_destroy = false
}

# Subnet for GKE and general workloads
resource "google_compute_subnetwork" "gke_subnet" {
  project       = var.project_id
  name          = "gke-subnet"
  ip_cidr_range = "10.0.0.0/20"
  region        = var.region
  network       = google_compute_network.shared_vpc.id
  description   = "Subnet for GKE clusters and general workloads"

  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "10.16.0.0/12"
  }

  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "10.32.0.0/16"
  }

  private_ip_google_access = true
}

# Cloud Router for NAT
resource "google_compute_router" "nat_router" {
  project = var.project_id
  name    = "nat-router"
  region  = var.region
  network = google_compute_network.shared_vpc.id
}

# Cloud NAT for outbound internet access from private IPs
resource "google_compute_router_nat" "nat" {
  project                            = var.project_id
  name                               = "nat-gateway"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall rule: Allow internal communication
resource "google_compute_firewall" "allow_internal" {
  project = var.project_id
  name    = "allow-internal"
  network = google_compute_network.shared_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    "10.0.0.0/20",  # Primary subnet
    "10.16.0.0/12", # GKE pods
    "10.32.0.0/16", # GKE services
  ]

  description = "Allow internal communication within VPC"
}

# Firewall rule: Allow SSH from IAP
resource "google_compute_firewall" "allow_iap_ssh" {
  project = var.project_id
  name    = "allow-iap-ssh"
  network = google_compute_network.shared_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  description   = "Allow SSH through Identity-Aware Proxy"
}

# Firewall rule: Allow health checks from Google Cloud
resource "google_compute_firewall" "allow_health_checks" {
  project = var.project_id
  name    = "allow-health-checks"
  network = google_compute_network.shared_vpc.name

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22",
  ]

  description = "Allow health checks from Google Cloud Load Balancers"
}

# ============================================
# GKE Cluster
# ============================================

# Note: Autopilot mode does not require a separate service account
# Google manages the service accounts automatically

# GKE Autopilot Cluster
resource "google_container_cluster" "shared_gke" {
  provider = google-beta
  project  = var.project_id
  name     = var.gke_cluster_name
  location = var.region

  # Enable Autopilot mode
  enable_autopilot = true

  deletion_protection = false

  # Explicit Workload Identity Config
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Enable Secret Manager CSI Driver (Top-level block)
  secret_manager_config {
    enabled = true
  }

  # Enable Secret Manager SecretSync (Top-level block)
  secret_sync_config {
    enabled = true
  }


  # VPC and Subnet configuration
  network    = google_compute_network.shared_vpc.self_link
  subnetwork = google_compute_subnetwork.gke_subnet.self_link

  # IP allocation policy for VPC-native cluster
  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Master authorized networks
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All networks"
    }
  }

  # Release channel
  release_channel {
    channel = var.gke_release_channel
  }

  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  # Note: Autopilot automatically manages:
  # - Node pools and scaling
  # - Logging and monitoring
  # - Network policies
  # - Workload Identity
  # - Security settings
  # - Addons (HTTP load balancing, HPA, etc.)
}
