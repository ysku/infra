output "vpc_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.shared_vpc.name
}

output "vpc_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.shared_vpc.id
}

output "vpc_self_link" {
  description = "The self link of the VPC network"
  value       = google_compute_network.shared_vpc.self_link
}

output "gke_subnet_name" {
  description = "The name of the GKE subnet"
  value       = google_compute_subnetwork.gke_subnet.name
}

output "gke_subnet_id" {
  description = "The ID of the GKE subnet"
  value       = google_compute_subnetwork.gke_subnet.id
}

output "gke_subnet_self_link" {
  description = "The self link of the GKE subnet"
  value       = google_compute_subnetwork.gke_subnet.self_link
}

output "gke_pods_range_name" {
  description = "The name of the secondary IP range for GKE pods"
  value       = "gke-pods"
}

output "gke_services_range_name" {
  description = "The name of the secondary IP range for GKE services"
  value       = "gke-services"
}

output "region" {
  description = "The region where resources are created"
  value       = var.region
}

# ============================================
# GKE Outputs
# ============================================

output "gke_cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.shared_gke.name
}

output "gke_cluster_id" {
  description = "The ID of the GKE cluster"
  value       = google_container_cluster.shared_gke.id
}

output "gke_cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = google_container_cluster.shared_gke.endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "The CA certificate of the GKE cluster"
  value       = google_container_cluster.shared_gke.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "gke_cluster_location" {
  description = "The location (region or zone) of the GKE cluster"
  value       = google_container_cluster.shared_gke.location
}

output "gke_workload_identity_pool" {
  description = "The Workload Identity pool for the GKE cluster"
  value       = "${var.project_id}.svc.id.goog"
}

# Note: Autopilot clusters do not have a user-managed service account
# Google automatically manages service accounts for Autopilot nodes


output "dns_name_servers" {
  description = "The name servers of the Cloud DNS managed zone"
  value       = google_dns_managed_zone.ysku_dev_zone.name_servers
}

output "shared_lb_ip_address" {
  description = "The global static IP address for the shared load balancer"
  value       = google_compute_global_address.shared_lb_ip.address
}
