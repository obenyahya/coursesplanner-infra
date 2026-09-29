# Réseau de l'environnement
module "network" {
  source = "../../modules/network"

  project_id   = module.project.project_id
  region       = var.region
  network_name = "coursesplanner-vpc"
  subnet_cidr  = "10.20.0.0/24"

  depends_on = [module.project] # l'API compute doit être active
}

# Cluster k3s (1 VM = 1 nœud)
module "k3s" {
  source = "../../modules/k3s"

  project_id   = module.project.project_id
  region       = var.region
  zone         = "${var.region}-a"
  name         = "k3s-stg"
  machine_type = "t2d-standard-1"
  network_id   = module.network.network_id
  subnet_id    = module.network.subnet_id

  environment  = "staging"
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
