variable "region" {
  description = "Primäre AWS-Region (Frankfurt)."
  type        = string
  default     = "eu-central-1"
}

variable "project" {
  description = "Projektname, wird als Präfix für Ressourcennamen und als Tag genutzt."
  type        = string
  default     = "glueckaufgames"
}

variable "github_repository" {
  description = "GitHub-Repository im Format owner/name, dem die OIDC-Rollen vertrauen."
  type        = string
  default     = "BohlBi/glueckaufgames-cloud"
}

variable "github_default_branch" {
  description = "Branch, von dem aus ausgerollt werden darf (terraform apply)."
  type        = string
  default     = "main"
}
