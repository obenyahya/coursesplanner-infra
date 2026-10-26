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
variable "k3s_node_name" {
  description = "Nom fixe du nœud k3s (null : k3s-<environment du cluster>, soit k3s-staging)"
  type        = string
  default     = null
}

variable "data_disk_size_gb" {
  description = "Taille du disque de données de la VM k3s (Go)"
  type        = number
  default     = 20
}

variable "persistent_volume_sizes" {
  description = "Capacité des PV hostPath postgres, redis et keycloak"
  type = object({
    postgres = string
    redis    = string
    keycloak = string
  })
  default = {
    postgres = "5Gi"
    redis    = "1Gi"
    keycloak = "1Gi"
  }
}

variable "expose_http_via_cloudflare" {
  description = "Ouvre le port 80 de la VM k3s aux seules plages IP de Cloudflare"
  type        = bool
  default     = false
}

variable "expose_https_via_cloudflare" {
  description = "Ouvre le port 443 de la VM k3s aux seules plages IP de Cloudflare (SSL « Full »)"
  type        = bool
  default     = false
}
