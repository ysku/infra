module "gh-actions-oidc" {
  source       = "../../../modules/gcp/gh-actions-oidc"
  project      = var.project_id
  repositories = var.repositories
}
