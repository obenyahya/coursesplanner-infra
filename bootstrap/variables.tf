variable "project_id" {
  description = "ID du projet GCP qui hébergera le state Terraform"
  type        = string
}

variable "region" {
  description = "Région GCP"
  type        = string
  default     = "europe-west9"
}