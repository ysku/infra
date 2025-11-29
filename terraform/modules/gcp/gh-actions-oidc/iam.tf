resource "google_iam_workload_identity_pool" "github_actions" {
  project                   = var.project
  workload_identity_pool_id = "github-actions-pool"
}

resource "google_iam_workload_identity_pool_provider" "github_actions" {
  project                            = var.project
  display_name                       = "github-actions-provider"
  workload_identity_pool_provider_id = "github-actions-provider"
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.repository"       = "assertion.repository"
    "attribute.actor"            = "assertion.actor"
    "attribute.repository_owner" = "assertion.repository_owner"
  }

  attribute_condition = "assertion.repository_owner == \"${var.repository_owner}\""
}

resource "google_service_account" "github_actions" {
  project    = var.project
  account_id = "github-actions"
}

resource "google_service_account_iam_binding" "github_actions_iam_workload_identity_user" {
  service_account_id = google_service_account.github_actions.id
  role               = "roles/iam.workloadIdentityUser"
  members = [
    for repo in var.repositories : "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions.name}/attribute.repository/${repo}"
  ]
}

# Allow Workload Identity Pool principals to create tokens for the service account
resource "google_service_account_iam_binding" "github_actions_token_creator_workload" {
  service_account_id = google_service_account.github_actions.id
  role               = "roles/iam.serviceAccountTokenCreator"
  members = [
    for repo in var.repositories : "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions.name}/attribute.repository/${repo}"
  ]
}

# Allow Workload Identity Pool principals to use the service account
resource "google_service_account_iam_binding" "github_actions_service_account_user" {
  service_account_id = google_service_account.github_actions.id
  role               = "roles/iam.serviceAccountUser"
  members = [
    for repo in var.repositories : "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions.name}/attribute.repository/${repo}"
  ]
}

resource "google_project_iam_member" "editor" {
  project = var.project
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Grant access to GCS bucket for Terraform state
resource "google_storage_bucket_iam_member" "terraform_state_admin" {
  bucket = "${var.project}-tfstates"
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.github_actions.email}"
}
