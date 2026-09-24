variable "project_id" {
  description = "ID du projet GCP des ressources partagées"
  type        = string
}

variable "region" {
  description = "Région GCP"
  type        = string
  default     = "europe-west9"
}

variable "registry_readers" {
  description = "Identités IAM autorisées à tirer les images du registry"
  type        = list(string)
  default     = []
}
