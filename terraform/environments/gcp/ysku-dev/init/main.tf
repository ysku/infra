module "gh-actions-oidc" {
  source           = "../../../../modules/gcp/gh-actions-oidc"
  project          = var.project_id
  repository_owner = var.repository_owner
  repositories     = var.repositories
}
