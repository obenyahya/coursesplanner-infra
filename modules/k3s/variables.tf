variable "project_id" {
  description = "ID du projet GCP"
  type        = string
}

variable "region" {
  description = "Région (pour l'IP statique)"
  type        = string
}

variable "zone" {
  description = "Zone de la VM (ex: europe-west9-a)"
  type        = string
}

variable "name" {
  description = "Nom de la VM et préfixe des ressources associées (ex: k3s-dev)"
  type        = string
}

variable "machine_type" {
  description = "Type de machine"
  type        = string
  default     = "e2-standard-2"
}

variable "disk_size_gb" {
  description = "Taille du disque système en Go"
  type        = number
  default     = 30
}

variable "network_id" {
  description = "VPC dans lequel ouvrir le pare-feu"
  type        = string
}

variable "subnet_id" {
  description = "Sous-réseau de la VM"
  type        = string
}

variable "app_namespace" {
  description = "Namespace Kubernetes de l'application (manifests de plateforme)"
  type        = string
  default     = "coursesplanner"
}

variable "registry_host" {
  description = "Hôte Artifact Registry pour lequel le Secret de pull est généré"
  type        = string
  default     = "europe-west9-docker.pkg.dev"
}

variable "test_image" {
  description = "Image complète de l'application de test ; vide = test-nginx n'est pas déployé"
  type        = string
  default     = ""
}
