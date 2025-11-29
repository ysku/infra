resource "google_project_service" "iamcredentials" {
  project = var.project
  service = "iamcredentials.googleapis.com"
}

resource "google_project_service" "iam" {
  project = var.project
  service = "iam.googleapis.com"
}

resource "google_project_service" "cloudresourcemanager" {
  project = var.project
  service = "cloudresourcemanager.googleapis.com"
}
