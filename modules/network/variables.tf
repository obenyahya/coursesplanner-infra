variable "project_id" {
  description = "ID du projet GCP"
  type        = string
}

variable "region" {
  description = "Région du sous-réseau"
  type        = string
}

variable "network_name" {
  description = "Nom du VPC"
  type        = string
}

variable "subnet_cidr" {
  description = "Plage d'IP privées du sous-réseau (ex: 10.10.0.0/24)"
  type        = string
}
