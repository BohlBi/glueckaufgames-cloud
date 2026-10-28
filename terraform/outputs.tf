output "website_url" {
  description = "Adresse der Website."
  value       = "https://${module.cdn.distribution_domain_name}"
}

output "distribution_id" {
  description = "ID der CloudFront-Distribution (für die Cache-Invalidierung)."
  value       = module.cdn.distribution_id
}

output "primary_bucket" {
  description = "Bucket in Frankfurt, in den die Website hochgeladen wird."
  value       = module.storage.primary_bucket_id
}

output "replica_bucket" {
  description = "Replikat in Irland."
  value       = module.storage.replica_bucket_id
}
