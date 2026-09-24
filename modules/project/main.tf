resource "google_project" "this" {
  project_id          = var.project_id
  name                = var.project_name
  folder_id           = var.folder_id
  billing_account     = var.billing_account
  auto_create_network = false
  deletion_policy     = "PREVENT"
}

resource "google_project_service" "apis" {
  for_each           = toset(var.apis)
  project            = google_project.this.project_id
  service            = each.value
  disable_on_destroy = false
}