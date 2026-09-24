output "repository_url" {
  description = "Préfixe à utiliser pour tagger et pousser les images"
  value       = "${google_artifact_registry_repository.this.location}-docker.pkg.dev/${google_artifact_registry_repository.this.project}/${google_artifact_registry_repository.this.repository_id}"
}
