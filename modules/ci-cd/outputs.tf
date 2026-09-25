output "workload_identity_provider" {
  description = "Nom complet du provider, à passer à google-github-actions/auth"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "service_account_email" {
  description = "Compte de service endossé par les workflows"
  value       = google_service_account.ci_builder.email
}
