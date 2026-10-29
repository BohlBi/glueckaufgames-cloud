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

variable "github_owner" {
  description = "GitHub-Konto, dem das Repository gehört."
  type        = string
  default     = "BohlBi"
}

variable "github_owner_id" {
  description = "Unveränderliche ID des GitHub-Kontos (Teil des OIDC-Subjects)."
  type        = number
  default     = 59445983
}

variable "github_repository" {
  description = "Name des Repositorys, dem die OIDC-Rollen vertrauen."
  type        = string
  default     = "glueckaufgames-cloud"
}

variable "github_repository_id" {
  description = "Unveränderliche ID des Repositorys (Teil des OIDC-Subjects)."
  type        = number
  default     = 1437531854
}

variable "github_default_branch" {
  description = "Branch, von dem aus ausgerollt werden darf (terraform apply)."
  type        = string
  default     = "main"
}

variable "enable_github_oidc" {
  description = "OIDC-Anbindung und Rollen für GitHub Actions anlegen. Für einen Nachbau ohne Pipeline auf false setzen."
  type        = bool
  default     = true
}
