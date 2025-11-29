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

# Service Account for GKE nodes
resource "google_service_account" "gke_nodes" {
  project      = var.project_id
  account_id   = "gke-nodes"
  display_name = "GKE Nodes Service Account"
  description  = "Service account used by GKE cluster nodes"
}

# Grant necessary permissions to the GKE nodes service account
resource "google_project_iam_member" "gke_nodes_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_resource_metadata_writer" {
  project = var.project_id
  role    = "roles/stackdriver.resourceMetadata.writer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# GKE Cluster
resource "google_container_cluster" "shared_gke" {
  project  = var.project_id
  name     = var.gke_cluster_name
  location = var.gke_regional ? var.region : var.gke_zone

  # VPC and Subnet configuration
  network    = google_compute_network.shared_vpc.self_link
  subnetwork = google_compute_subnetwork.gke_subnet.self_link

  # IP allocation policy for VPC-native cluster
  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }

  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  # Network policy
  network_policy {
    enabled  = true
    provider = "PROVIDER_UNSPECIFIED"
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
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

  # Addons configuration
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    network_policy_config {
      disabled = false
    }
    gcp_filestore_csi_driver_config {
      enabled = true
    }
    gcs_fuse_csi_driver_config {
      enabled = true
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

  # Logging and monitoring
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
    }
  }

  # Security settings
  binary_authorization {
    evaluation_mode = "DISABLED"
  }

  # Enable Autopilot mode (optional)
  # enable_autopilot = var.gke_autopilot

  lifecycle {
    ignore_changes = [
      initial_node_count,
    ]
  }
}

# Node Pool
resource "google_container_node_pool" "primary_nodes" {
  project    = var.project_id
  name       = "primary-node-pool"
  location   = var.gke_regional ? var.region : var.gke_zone
  cluster    = google_container_cluster.shared_gke.name
  node_count = var.gke_node_count

  # Autoscaling configuration
  autoscaling {
    min_node_count = var.gke_min_node_count
    max_node_count = var.gke_max_node_count
  }

  # Node configuration
  node_config {
    machine_type    = var.gke_machine_type
    disk_size_gb    = var.gke_disk_size_gb
    disk_type       = "pd-standard"
    service_account = google_service_account.gke_nodes.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Enable GCR/Artifact Registry access
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Labels
    labels = {
      environment = "development"
      managed-by  = "terraform"
    }

    # Tags
    tags = ["gke-node", "shared-gke"]

    # Shielded instance config
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  # Management
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
