output "workload_identity_provider" {
  description = "The ID of the workload identity provider for GitHub Actions"
  value       = module.gh-actions-oidc.workload_identity_provider
}

output "service_account_email" {
  description = "The email of the service account for GitHub Actions"
  value       = module.gh-actions-oidc.service_account_email
}
