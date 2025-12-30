# Referencing Shared Resources
data "google_dns_managed_zone" "ysku_dev_zone" {
  name    = "ysku-dev-zone"
  project = var.project_id
}

data "google_compute_global_address" "shared_lb_ip" {
  name    = "shared-lb-ip"
  project = var.project_id
}

# ============================================
# DNS Configuration
# ============================================

resource "google_dns_record_set" "allies" {
  project      = var.project_id
  name         = "allies.dev.ysku.me."
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.ysku_dev_zone.name
  rrdatas      = [data.google_compute_global_address.shared_lb_ip.address]
}

# ============================================
# IAM & Workload Identity
# ============================================

# Service Account for Allies API
resource "google_service_account" "allies_sa" {
  project      = var.project_id
  account_id   = "allies-sa"
  display_name = "Service Account for Allies API"
}

# Allow K8s ServiceAccount to impersonate GCP Service Account
resource "google_service_account_iam_member" "allies_wi_binding" {
  service_account_id = google_service_account.allies_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[allies/allies-api]"
}

# Grant Secret Manager Access
resource "google_project_iam_member" "allies_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.allies_sa.email}"
}
