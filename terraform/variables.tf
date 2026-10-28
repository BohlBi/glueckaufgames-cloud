variable "project" {
  description = "Projektname, Präfix für alle Ressourcen."
  type        = string
  default     = "glueckaufgames"
}

variable "primary_region" {
  description = "Region des primären Buckets."
  type        = string
  default     = "eu-central-1"
}

variable "replica_region" {
  description = "Region des Replikats für den Failover."
  type        = string
  default     = "eu-west-1"
}

variable "alert_email" {
  description = "E-Mail-Adresse für Budget- und Fehler-Alarme."
  type        = string
}

variable "monthly_budget_usd" {
  description = "Monatliches Budget für das Hosting in USD."
  type        = number
  default     = 10
}

variable "budget_alert_threshold_percent" {
  description = "Ab diesem Anteil des Budgets wird per E-Mail gewarnt."
  type        = number
  default     = 80
}

variable "price_class" {
  description = "CloudFront-Preisklasse. PriceClass_All, da 30 % der Besucher aus Asien kommen."
  type        = string
  default     = "PriceClass_All"
}
