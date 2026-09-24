variable "project_id" {
  description = "ID du projet GCP de l'environnement"
  type        = string
}

variable "region" {
  description = "Région GCP"
  type        = string
  default     = "europe-west9"
}

variable "environment" {
  description = "Nom de l'environnement"
  type        = string
}

variable "folder_id" {
  type = string
}

variable "billing_account" {
  type = string
}