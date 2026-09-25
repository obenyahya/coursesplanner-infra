output "registry_url" {
  value = module.registry.repository_url
}

# À copier dans les variables GitHub du dépôt applicatif
output "workload_identity_provider" {
  value = module.ci_cd.workload_identity_provider
}

output "ci_service_account_email" {
  value = module.ci_cd.service_account_email
}
