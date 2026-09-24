# Réseau de l'environnement
module "network" {
  source = "../../modules/network"

  project_id   = module.project.project_id
  region       = var.region
  network_name = "coursesplanner-vpc"
  subnet_cidr  = "10.10.0.0/24"

  depends_on = [module.project] # l'API compute doit être active
}

# Cluster k3s (1 VM = 1 nœud)
module "k3s" {
  source = "../../modules/k3s"

  project_id   = module.project.project_id
  region       = var.region
  zone         = "${var.region}-a"
  name         = "k3s-dev"
  machine_type = "t2d-standard-1"
  network_id   = module.network.network_id
  subnet_id    = module.network.subnet_id

  # Manifests de plateforme livrés au cluster par Terraform
  app_namespace = "coursesplanner"
  registry_host = "europe-west9-docker.pkg.dev"
  test_image    = "europe-west9-docker.pkg.dev/coursesplanner-infra/apps/test-nginx:v1"
}

output "k3s_ip" {
  value = module.k3s.external_ip
}

output "ssh_command" {
  value = "gcloud compute ssh ${module.k3s.instance_name} --zone=${module.k3s.zone} --project=${var.project_id} --tunnel-through-iap"
}
