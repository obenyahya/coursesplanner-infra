# VPC : le réseau privé du projet
resource "google_compute_network" "this" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false # pas de sous-réseau automatique dans chaque région
}

# Sous-réseau régional (Paris)
resource "google_compute_subnetwork" "main" {
  project                  = var.project_id
  name                     = "${var.network_name}-${var.region}"
  region                   = var.region
  network                  = google_compute_network.this.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true # accès aux API Google sans passer par Internet
}
