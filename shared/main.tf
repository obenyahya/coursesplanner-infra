terraform {
  required_version = ">= 1.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.4"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region

  default_labels = {
    app         = "coursesplanner"
    environment = "shared"
    managed_by  = "terraform"
  }
}

resource "google_project_service" "artifactregistry" {
  service = "artifactregistry.googleapis.com"
  # Ne pas couper l'API au destroy : d'autres ressources du projet pourraient en dépendre
  disable_on_destroy = false
}

module "registry" {
  source = "../modules/registry"

  project_id    = var.project_id
  location      = var.region
  repository_id = "apps"
  readers       = var.registry_readers

  # Le dépôt ne peut pas être créé tant que l'API n'est pas active
  depends_on = [google_project_service.artifactregistry]
}

# API nécessaires à Workload Identity Federation :
# sts échange le jeton GitHub, iamcredentials délivre le jeton du compte de service
resource "google_project_service" "ci" {
  for_each = toset([
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}

module "ci_cd" {
  source = "../modules/ci-cd"

  project_id        = var.project_id
  github_repository = "obenyahya/coursesplanner-docker"
  # Sorties du module registry : droit limité à ce dépôt, créé avant lui
  registry_location      = module.registry.location
  registry_repository_id = module.registry.repository_id

  depends_on = [google_project_service.ci]
}
