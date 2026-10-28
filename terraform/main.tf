module "storage" {
  source = "./modules/storage"

  project = var.project

  providers = {
    aws         = aws
    aws.replica = aws.replica
  }
}

module "cdn" {
  source = "./modules/cdn"

  project               = var.project
  price_class           = var.price_class
  primary_bucket_id     = module.storage.primary_bucket_id
  primary_bucket_arn    = module.storage.primary_bucket_arn
  primary_bucket_domain = module.storage.primary_bucket_regional_domain_name
  replica_bucket_id     = module.storage.replica_bucket_id
  replica_bucket_arn    = module.storage.replica_bucket_arn
  replica_bucket_domain = module.storage.replica_bucket_regional_domain_name

  providers = {
    aws         = aws
    aws.replica = aws.replica
  }
}

module "monitoring" {
  source = "./modules/monitoring"

  project                        = var.project
  alert_email                    = var.alert_email
  monthly_budget_usd             = var.monthly_budget_usd
  budget_alert_threshold_percent = var.budget_alert_threshold_percent
  distribution_id                = module.cdn.distribution_id

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}
