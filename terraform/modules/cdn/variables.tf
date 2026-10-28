variable "project" {
  description = "Projektname, Präfix für Ressourcennamen."
  type        = string
}

variable "price_class" {
  description = "CloudFront-Preisklasse."
  type        = string
}

variable "primary_bucket_id" {
  description = "Name des primären Buckets."
  type        = string
}

variable "primary_bucket_arn" {
  description = "ARN des primären Buckets."
  type        = string
}

variable "primary_bucket_domain" {
  description = "Regionaler Endpunkt des primären Buckets."
  type        = string
}

variable "replica_bucket_id" {
  description = "Name des Replikats."
  type        = string
}

variable "replica_bucket_arn" {
  description = "ARN des Replikats."
  type        = string
}

variable "replica_bucket_domain" {
  description = "Regionaler Endpunkt des Replikats."
  type        = string
}
