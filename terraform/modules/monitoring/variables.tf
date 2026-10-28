variable "project" {
  description = "Projektname, Präfix für Ressourcennamen."
  type        = string
}

variable "alert_email" {
  description = "Empfänger für Budget- und Fehler-Alarme."
  type        = string
}

variable "monthly_budget_usd" {
  description = "Monatliches Budget in USD."
  type        = number
}

variable "budget_alert_threshold_percent" {
  description = "Warnschwelle in Prozent des Budgets."
  type        = number
}

variable "distribution_id" {
  description = "ID der überwachten CloudFront-Distribution."
  type        = string
}
