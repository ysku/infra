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
