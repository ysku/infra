output "workload_identity_provider" {
  description = "The ID of the workload identity provider for GitHub Actions"
  value       = google_iam_workload_identity_pool_provider.github_actions.name
}

output "service_account_email" {
  description = "The email of the service account for GitHub Actions"
  value       = google_service_account.github_actions.email
}

output "workload_identity_pool_id" {
  description = "The ID of the workload identity pool"
  value       = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
}
