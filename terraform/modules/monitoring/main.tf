# -----------------------------------------------------------------------------
# Kostenkontrolle und Überwachung
# - AWS Budget: E-Mail bei 80 % des Monatsbudgets
# - CloudWatch: E-Mail, wenn CloudFront viele Serverfehler (5xx) ausliefert
# -----------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

resource "aws_budgets_budget" "monthly" {
  name         = "${var.project}-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.budget_alert_threshold_percent
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
}

# CloudFront-Metriken liegen in us-east-1, Alarm und Topic deshalb auch.
resource "aws_sns_topic" "alerts" {
  #checkov:skip=CKV_AWS_26:Mit dem AWS-verwalteten SNS-Schlüssel kann CloudWatch nicht veröffentlichen; ein eigener KMS-Schlüssel würde das Budget belasten. Inhalt: nur Alarmmeldungen.
  provider = aws.us_east_1
  name     = "${var.project}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  provider  = aws.us_east_1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx" {
  provider            = aws.us_east_1
  alarm_name          = "${var.project}-cloudfront-5xx"
  alarm_description   = "Mehr als 5 % der Anfragen enden mit einem Serverfehler (5xx)."
  namespace           = "AWS/CloudFront"
  metric_name         = "5xxErrorRate"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = var.distribution_id
    Region         = "Global"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}
