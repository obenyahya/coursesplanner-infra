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
    environment = var.environment
    managed_by  = "terraform"
  }
}

module "project" {
  source = "../../modules/project"

  project_id      = var.project_id
  project_name    = "coursesplanner-prod"
  folder_id       = var.folder_id
  billing_account = var.billing_account

  apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iap.googleapis.com",
  ]
}

import {
  to = module.project.google_project.this
  id = "coursesplanner-prod"
}