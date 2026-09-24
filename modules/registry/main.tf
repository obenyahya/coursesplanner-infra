# Dépôt Docker commun aux 3 environnements : une même image est promue dev → staging → prod
resource "google_artifact_registry_repository" "this" {
  project       = var.project_id
  location      = var.location
  repository_id = var.repository_id
  format        = "DOCKER"
  description   = "Images Docker des microservices CoursesPlanner"

  labels = {
    component = "registry"
  }

  # FinOps : on nettoie automatiquement pour ne pas payer le stockage d'images inutiles.
  # Les règles KEEP sont prioritaires sur les DELETE : les keep_count dernières versions
  # de chaque image ne sont jamais supprimées, même si elles ont plus de 90 jours.
  cleanup_policies {
    id     = "keep-recent-versions"
    action = "KEEP"
    most_recent_versions {
      keep_count = var.keep_count
    }
  }

  # Images sans tag = anciennes couches remplacées par un nouveau push du même tag
  cleanup_policies {
    id     = "delete-untagged-7d"
    action = "DELETE"
    condition {
      tag_state  = "UNTAGGED"
      older_than = "604800s" # 7 jours
    }
  }

  cleanup_policies {
    id     = "delete-old-90d"
    action = "DELETE"
    condition {
      tag_state  = "ANY"
      older_than = "7776000s" # 90 jours
    }
  }
}

# Lecture accordée sur le dépôt seulement (et non sur le projet) :
# principe du moindre privilège, les lecteurs ne voient pas les autres dépôts.
resource "google_artifact_registry_repository_iam_member" "readers" {
  for_each = toset(var.readers)

  project    = google_artifact_registry_repository.this.project
  location   = google_artifact_registry_repository.this.location
  repository = google_artifact_registry_repository.this.name
  role       = "roles/artifactregistry.reader"
  member     = each.value
}
