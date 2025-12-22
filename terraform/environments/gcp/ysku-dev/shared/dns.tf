resource "google_dns_managed_zone" "ysku_dev_zone" {
  project     = var.project_id
  name        = "ysku-dev-zone"
  dns_name    = var.dns_domain
  description = "Managed zone for ysku-dev subdomain delegated from AWS"
  visibility  = "public"
}
