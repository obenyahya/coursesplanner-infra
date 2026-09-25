# ---------------------------------------------------------------
# Pare-feu : propre aux nœuds k3s (tag "k3s")
# ---------------------------------------------------------------

# Web public : HTTP/HTTPS vers Traefik
resource "google_compute_firewall" "allow_web" {
  project       = var.project_id
  name          = "${var.name}-allow-web"
  network       = var.network_id
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["k3s"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

# SSH et API Kubernetes : uniquement via IAP (jamais depuis Internet)
resource "google_compute_firewall" "allow_iap" {
  project       = var.project_id
  name          = "${var.name}-allow-iap"
  network       = var.network_id
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"] # plage d'IP d'IAP
  target_tags   = ["k3s"]

  allow {
    protocol = "tcp"
    ports    = ["22", "6443"]
  }
}

# ---------------------------------------------------------------
# IP publique statique (ne change pas au redémarrage)
# ---------------------------------------------------------------
resource "google_compute_address" "this" {
  project = var.project_id
  name    = "${var.name}-ip"
  region  = var.region
}

# ---------------------------------------------------------------
# Identité de la VM, avec le minimum de droits
# ---------------------------------------------------------------
resource "google_service_account" "this" {
  project      = var.project_id
  account_id   = var.name
  display_name = "VM ${var.name}"
}

resource "google_project_iam_member" "logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.this.email}"
}

resource "google_project_iam_member" "monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.this.email}"
}

# ---------------------------------------------------------------
# La VM : un cluster k3s à un seul nœud
# ---------------------------------------------------------------
resource "google_compute_instance" "this" {
  project      = var.project_id
  name         = var.name
  zone         = var.zone
  machine_type = var.machine_type
  tags         = ["k3s"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = var.disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = var.subnet_id
    access_config {
      nat_ip = google_compute_address.this.address
    }
  }

  service_account {
    email  = google_service_account.this.email
    scopes = ["cloud-platform"] # les droits réels sont fixés par IAM
  }

  shielded_instance_config {
    enable_secure_boot = true
  }

  # Passé via "metadata" (et non metadata_startup_script) :
  # modifier le script ne recrée pas la VM, il s'appliquera au prochain démarrage.
  metadata = {
    enable-oslogin = "TRUE"
    startup-script = file("${path.module}/startup.sh")
  }

  allow_stopping_for_update = true
}
