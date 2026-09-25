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
