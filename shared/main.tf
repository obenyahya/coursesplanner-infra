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
