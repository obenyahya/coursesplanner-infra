# Réseau de l'environnement
module "network" {
  source = "../../modules/network"

  project_id   = module.project.project_id
  region       = var.region
  network_name = "coursesplanner-vpc"
  subnet_cidr  = "10.20.0.0/24"

  depends_on = [module.project] # l'API compute doit être active
}

# Plages IPv4 de Cloudflare, lues à chaque plan (pas de provider Cloudflare ni de token)
data "http" "cloudflare_ipv4" {
  count = local.cloudflare_enabled ? 1 : 0

  url = "https://www.cloudflare.com/ips-v4"

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Impossible de récupérer https://www.cloudflare.com/ips-v4 (HTTP ${self.status_code})."
    }
  }
}

locals {
  cloudflare_enabled = var.expose_http_via_cloudflare || var.expose_https_via_cloudflare
  cloudflare_ipv4_ranges = local.cloudflare_enabled ? [
    for line in split("\n", data.http.cloudflare_ipv4[0].response_body) : trimspace(line)
    if trimspace(line) != ""
  ] : []
}

# Cluster k3s (1 VM = 1 nœud)
locals {
  k3s_environment = "staging"
}

module "k3s" {
  source = "../../modules/k3s"

  project_id   = module.project.project_id
  region       = var.region
  zone         = "${var.region}-a"
  name         = "k3s-stg"
  machine_type = "t2d-standard-2"
  network_id   = module.network.network_id
  subnet_id    = module.network.subnet_id
  internal_ip  = "10.20.0.2" # IP déjà attribuée à la VM, désormais réservée
  public_web   = false       # staging : pas d'ouverture à tout Internet

  # staging derrière Cloudflare (SSL Full) : port 443 ouvert aux seules IP Cloudflare, 80 fermé
  expose_http_via_cloudflare  = var.expose_http_via_cloudflare
  expose_https_via_cloudflare = var.expose_https_via_cloudflare
  cloudflare_ipv4_ranges      = local.cloudflare_ipv4_ranges

  data_disk_size_gb       = var.data_disk_size_gb
  persistent_volume_sizes = var.persistent_volume_sizes

  environment  = local.k3s_environment
  node_name    = coalesce(var.k3s_node_name, "k3s-${local.k3s_environment}")
  app_branch   = "staging"
  app_repo_url = "ssh://git@github.com/obenyahya/coursesplanner-docker"
  flux_version = "2.9.5"

  depends_on = [module.project] # l'API secretmanager doit être active
}

output "k3s_ip" {
  value = module.k3s.external_ip
}

output "ssh_command" {
  value = "gcloud compute ssh ${module.k3s.instance_name} --zone=${module.k3s.zone} --project=${var.project_id} --tunnel-through-iap"
}
