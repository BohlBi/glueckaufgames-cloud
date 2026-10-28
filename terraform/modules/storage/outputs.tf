output "primary_bucket_id" {
  description = "Name des primären Buckets."
  value       = aws_s3_bucket.primary.id
}

output "primary_bucket_arn" {
  description = "ARN des primären Buckets."
  value       = aws_s3_bucket.primary.arn
}

output "primary_bucket_regional_domain_name" {
  description = "Regionaler Endpunkt des primären Buckets (Origin für CloudFront)."
  value       = aws_s3_bucket.primary.bucket_regional_domain_name
}

output "replica_bucket_id" {
  description = "Name des Replikats."
  value       = aws_s3_bucket.replica.id
}

output "replica_bucket_arn" {
  description = "ARN des Replikats."
  value       = aws_s3_bucket.replica.arn
}

output "replica_bucket_regional_domain_name" {
  description = "Regionaler Endpunkt des Replikats (Failover-Origin für CloudFront)."
  value       = aws_s3_bucket.replica.bucket_regional_domain_name
}
