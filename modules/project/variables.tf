variable "project_id" {
  description = "ID unique du projet (mondial, immuable)"
  type        = string
}

variable "project_name" {
  description = "Nom affiché dans la console"
  type        = string
}

variable "folder_id" {
  description = "ID du dossier GCP parent"
  type        = string
}

variable "billing_account" {
  description = "ID du compte de facturation (format XXXXXX-XXXXXX-XXXXXX)"
  type        = string
}

variable "apis" {
  description = "Liste des API à activer"
  type        = list(string)
  default     = []
}