variable "project_id" {
  description = "ID du projet GCP qui héberge le pool d'identités et le compte de service"
  type        = string
}

variable "github_repository" {
  description = "Seul dépôt GitHub autorisé, au format <owner>/<repo>"
  type        = string
}

variable "registry_location" {
  description = "Région du dépôt Artifact Registry sur lequel la CI pousse"
  type        = string
}

variable "registry_repository_id" {
  description = "Nom du dépôt Artifact Registry sur lequel la CI pousse (ex: apps)"
  type        = string
}
