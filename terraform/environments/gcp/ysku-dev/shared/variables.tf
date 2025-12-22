variable "project_id" {
  type        = string
  description = "Google Cloud project ID"
}

variable "region" {
  type        = string
  description = "GCP region for regional resources"
  default     = "asia-northeast1"
}

# ============================================
# GKE Variables
# ============================================

variable "gke_cluster_name" {
  type        = string
  description = "Name of the GKE cluster"
  default     = "shared-gke"
}

variable "gke_regional" {
  type        = bool
  description = "Whether to create a regional cluster (true) or zonal cluster (false)"
  default     = false
}

variable "gke_zone" {
  type        = string
  description = "Zone for zonal GKE cluster"
  default     = "asia-northeast1-a"
}

variable "gke_release_channel" {
  type        = string
  description = "Release channel for GKE cluster (RAPID, REGULAR, STABLE)"
  default     = "REGULAR"
}

variable "gke_node_count" {
  type        = number
  description = "Initial number of nodes in the node pool"
  default     = 1
}

variable "gke_min_node_count" {
  type        = number
  description = "Minimum number of nodes in the node pool"
  default     = 1
}

variable "gke_max_node_count" {
  type        = number
  description = "Maximum number of nodes in the node pool"
  default     = 3
}

variable "gke_machine_type" {
  type        = string
  description = "Machine type for GKE nodes"
  default     = "e2-medium"
}

variable "gke_disk_size_gb" {
  type        = number
  description = "Disk size for GKE nodes in GB"
  default     = 50
}

variable "gke_spot_enabled" {
  type        = bool
  description = "Whether to use Spot VMs for GKE nodes (preemptible)"
  default     = false
}


# ============================================
# DNS Variables
# ============================================

variable "dns_domain" {
  type        = string
  description = "The DNS name of this managed zone, for instance \"example.com.\". Inherited from AWS Route53."
}
