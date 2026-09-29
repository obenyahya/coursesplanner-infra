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

variable "node_name" {
  description = "Nom fixe du nœud k3s (écrit dans /etc/rancher/k3s/config.yaml). null : nom tiré du hostname de la VM"
  type        = string
  default     = null

  validation {
    condition     = var.node_name == null || can(regex("^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?$", var.node_name))
    error_message = "node_name doit être un label DNS valide (minuscules, chiffres, tirets)."
  }
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

variable "environment" {
  description = "Nom court du cluster : choisit l'overlay k8s/overlays/<environment> de coursesplanner-docker"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment doit valoir dev, staging ou prod."
  }
}

variable "app_branch" {
  description = "Branche de coursesplanner-docker suivie par Flux"
  type        = string

  validation {
    condition     = contains(["develop", "staging", "main"], var.app_branch)
    error_message = "app_branch doit valoir develop, staging ou main."
  }
}

variable "app_repo_url" {
  description = "URL SSH du dépôt applicatif surveillé par Flux (uniquement son dossier k8s/)"
  type        = string
  default     = "ssh://git@github.com/obenyahya/coursesplanner-docker"
}

variable "flux_version" {
  description = "Version de Flux (release fluxcd/flux2, sans le « v »)"
  type        = string
}

variable "external_secrets_version" {
  description = "Version du chart Helm external-secrets"
  type        = string
  default     = "2.11.0"
}

variable "internal_ip" {
  description = "IP interne réservée (statique) de la VM, dans subnet_id. null : IP éphémère"
  type        = string
  default     = null
}

variable "public_web" {
  description = "Ouvre 80/443 depuis Internet (false : accès uniquement par tunnel IAP)"
  type        = bool
  default     = true
}

variable "data_disk_size_gb" {
  description = "Taille du disque de données persistant (monté sur /mnt/data) en Go"
  type        = number
  default     = 20
}

variable "snapshot_retention_days" {
  description = "Durée de conservation des snapshots quotidiens du disque de données"
  type        = number
  default     = 7
}

variable "persistent_volume_sizes" {
  description = "Capacité des PV hostPath sur le disque de données"
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

variable "auth_provider_gcp_version" {
  description = "Build de auth-provider-gcp (credential provider kubelet pour Artifact Registry)"
  type        = string
  default     = "v20251205-ccmv34.2.0"
}

variable "auth_provider_gcp_sha256" {
  description = "SHA-256 du binaire linux-amd64 de auth_provider_gcp_version"
  type        = string
  default     = "568d16b9a250a808ab0ef580e4fc8a04cd04836deaa422102af39a313096e165"
}
