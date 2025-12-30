resource "google_compute_global_address" "shared_lb_ip" {
  project      = var.project_id
  name         = "shared-lb-ip"
  address_type = "EXTERNAL"
  description  = "Global static IP for Shared Load Balancer"
}
