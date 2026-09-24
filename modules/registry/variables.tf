variable "project_id" {
  description = "ID du projet GCP qui héberge le dépôt"
  type        = string
}

variable "location" {
  description = "Région du dépôt (ex: europe-west9)"
  type        = string
}

variable "repository_id" {
  description = "Nom du dépôt (ex: apps)"
  type        = string
}

variable "readers" {
  description = "Identités IAM autorisées à tirer les images (ex: serviceAccount:xxx@yyy.iam.gserviceaccount.com)"
  type        = list(string)
  default     = []
}

variable "keep_count" {
  description = "Nombre de versions les plus récentes à conserver pour chaque image"
  type        = number
  default     = 10
}
