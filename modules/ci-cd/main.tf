# ---------------------------------------------------------------
# Workload Identity Federation : GitHub Actions obtient un jeton GCP court
# en échange de son jeton OIDC, sans aucune clé JSON à stocker dans GitHub.
# ---------------------------------------------------------------
resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub OIDC"

  # Claims du jeton GitHub recopiés en attributs Google, utilisables dans l'IAM
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # Filtre à l'entrée : l'émetteur GitHub est partagé par TOUS les dépôts du monde,
  # sans cette condition n'importe quel dépôt pourrait échanger son jeton ici.
  attribute_condition = "assertion.repository == \"${var.github_repository}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Identité GCP endossée par les workflows
resource "google_service_account" "ci_builder" {
  project      = var.project_id
  account_id   = "ci-builder"
  display_name = "CI GitHub Actions (${var.github_repository})"
}

# Seules les exécutions du dépôt autorisé peuvent endosser ce compte
resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = google_service_account.ci_builder.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}

# Push d'images sur le dépôt "apps" uniquement : pas de droit sur le reste du projet
resource "google_artifact_registry_repository_iam_member" "writer" {
  project    = var.project_id
  location   = var.registry_location
  repository = var.registry_repository_id
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.ci_builder.email}"
}
