# ---------------------------------------------------------------
# Pare-feu : propre aux nœuds k3s (tag "k3s")
# ---------------------------------------------------------------

# Web public : HTTP/HTTPS (désactivable : le dev n'est joignable que par tunnel IAP)
resource "google_compute_firewall" "allow_web" {
  count = var.public_web ? 1 : 0

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

moved {
  from = google_compute_firewall.allow_web
  to   = google_compute_firewall.allow_web[0]
}

# HTTP (80) uniquement depuis Cloudflare : utile seulement en SSL « Flexible »
# (Cloudflare → origine en HTTP) ; à fermer en SSL « Full », qui passe par le 443
resource "google_compute_firewall" "allow_http_cloudflare" {
  count = var.expose_http_via_cloudflare ? 1 : 0

  project       = var.project_id
  name          = "${var.name}-allow-http-cloudflare"
  network       = var.network_id
  direction     = "INGRESS"
  source_ranges = var.cloudflare_ipv4_ranges
  target_tags   = ["k3s"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  lifecycle {
    precondition {
      condition     = length(var.cloudflare_ipv4_ranges) > 0
      error_message = "expose_http_via_cloudflare = true exige cloudflare_ipv4_ranges non vide."
    }
  }
}

# HTTPS (443) uniquement depuis Cloudflare (SSL « Full » : Cloudflare → origine en HTTPS)
resource "google_compute_firewall" "allow_https_cloudflare" {
  count = var.expose_https_via_cloudflare ? 1 : 0

  project       = var.project_id
  name          = "${var.name}-allow-https-cloudflare"
  network       = var.network_id
  direction     = "INGRESS"
  source_ranges = var.cloudflare_ipv4_ranges
  target_tags   = ["k3s"]

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  lifecycle {
    precondition {
      condition     = length(var.cloudflare_ipv4_ranges) > 0
      error_message = "expose_https_via_cloudflare = true exige cloudflare_ipv4_ranges non vide."
    }
  }
}

# SSH uniquement via IAP (jamais depuis Internet) ; l'API Kubernetes (6443) reste fermée
resource "google_compute_firewall" "allow_iap" {
  project       = var.project_id
  name          = "${var.name}-allow-iap"
  network       = var.network_id
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"] # plage d'IP d'IAP
  target_tags   = ["k3s"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# ---------------------------------------------------------------
# IP publique et IP interne statiques (ne changent pas si la VM est recréée)
# ---------------------------------------------------------------
resource "google_compute_address" "this" {
  project = var.project_id
  name    = "${var.name}-ip"
  region  = var.region
}

# Réserver l'IP déjà attribuée à la VM la rend statique, sans toucher à la VM
resource "google_compute_address" "internal" {
  count = var.internal_ip != null ? 1 : 0

  project      = var.project_id
  name         = "${var.name}-internal-ip"
  region       = var.region
  address_type = "INTERNAL"
  subnetwork   = var.subnet_id
  address      = var.internal_ip
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
# Lecture de tous les secrets du projet
# Les ExternalSecrets (ClusterSecretStore gcp-secret-manager) lisent n'importe quel
# secret du projet. Binding déjà créé à la main : iam_member est non autoritaire,
# Terraform le reprend sans import.
# ---------------------------------------------------------------
resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
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
    network_ip = one(google_compute_address.internal[*].address)
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

  # Passé via "metadata" (et non metadata_startup_script) : modifier le script ou
  # les manifests met la VM à jour sur place, sans la recréer ; pris en compte au
  # prochain démarrage (ou par « sudo google_metadata_script_runner startup »).
  # Aucun secret ici : la clé de déploiement Flux est lue dans Secret Manager.
  metadata = {
    enable-oslogin         = "TRUE"
    startup-script         = templatefile("${path.module}/startup.sh.tftpl", local.startup_vars)
    flux-version           = var.flux_version
    flux-deploy-key-secret = google_secret_manager_secret.flux_deploy_key.secret_id
    k3s-manifests          = local.manifests
  }

  allow_stopping_for_update = true

  # Le disque de données est attaché par google_compute_attached_disk
  lifecycle {
    ignore_changes = [attached_disk]
  }
}

# ---------------------------------------------------------------
# Disque de données persistant : survit à la VM (jetable), sauvegardé chaque jour
# ---------------------------------------------------------------
resource "google_compute_disk" "data" {
  project = var.project_id
  name    = "${var.name}-data"
  zone    = var.zone
  type    = "pd-balanced"
  size    = var.data_disk_size_gb

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_resource_policy" "data_snapshots" {
  project = var.project_id
  name    = "${var.name}-data-daily"
  region  = var.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "03:00" # UTC
      }
    }
    retention_policy {
      max_retention_days    = var.snapshot_retention_days
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
    snapshot_properties {
      storage_locations = [var.region]
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "data_snapshots" {
  project = var.project_id
  name    = google_compute_resource_policy.data_snapshots.name
  disk    = google_compute_disk.data.name
  zone    = var.zone
}

# device_name "data" : visible dans la VM sous /dev/disk/by-id/google-data
resource "google_compute_attached_disk" "data" {
  project     = var.project_id
  zone        = var.zone
  instance    = google_compute_instance.this.id
  disk        = google_compute_disk.data.id
  device_name = "data"
}

# ---------------------------------------------------------------
# Manifests déposés par startup.sh dans le dossier d'auto-déploiement de k3s
# ---------------------------------------------------------------
locals {
  manifest_vars = {
    project_id               = var.project_id
    environment              = var.environment
    app_branch               = var.app_branch
    app_repo_url             = var.app_repo_url
    external_secrets_version = var.external_secrets_version
  }

  data_mount = "/mnt/data"

  # Un PV hostPath par service à état ; uid/gid = runAsUser/runAsGroup des pods
  # (hostPath ignore fsGroup : les dossiers doivent déjà appartenir au bon utilisateur)
  data_volumes = {
    postgres = { claim = "data-postgres-0", size = var.persistent_volume_sizes.postgres, owner = "999:999" }
    redis    = { claim = "data-redis-0", size = var.persistent_volume_sizes.redis, owner = "999:1000" }
    keycloak = { claim = "keycloak-data", size = var.persistent_volume_sizes.keycloak, owner = "1000:0" }
  }

  manifests = join("\n---\n", concat(
    [
      for f in ["namespace", "external-secrets", "flux-sync"] :
      templatefile("${path.module}/manifests/${f}.yaml.tftpl", local.manifest_vars)
    ],
    [
      for name, v in local.data_volumes :
      templatefile("${path.module}/manifests/persistent-volume.yaml.tftpl", {
        name  = name
        size  = v.size
        claim = v.claim
        path  = "${local.data_mount}/${name}"
      })
    ],
  ))

  startup_vars = {
    node_name                 = var.node_name
    data_mount                = local.data_mount
    data_volumes              = local.data_volumes
    auth_provider_gcp_version = var.auth_provider_gcp_version
    auth_provider_gcp_sha256  = var.auth_provider_gcp_sha256
  }
}

# ---------------------------------------------------------------
# Clé SSH de Flux (lecture seule sur coursesplanner-docker).
# Secret vide : la version est ajoutée à la main (gcloud secrets versions add),
# la clé privée n'apparaît donc jamais dans le state Terraform.
# ---------------------------------------------------------------
resource "google_secret_manager_secret" "flux_deploy_key" {
  project   = var.project_id
  secret_id = "flux-deploy-key"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

# Lecture de CE secret uniquement par la VM
resource "google_secret_manager_secret_iam_member" "flux_deploy_key" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.flux_deploy_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.this.email}"
}
