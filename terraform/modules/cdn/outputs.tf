output "distribution_id" {
  description = "ID der CloudFront-Distribution."
  value       = aws_cloudfront_distribution.website.id
}

output "distribution_domain_name" {
  description = "Domain der CloudFront-Distribution (*.cloudfront.net)."
  value       = aws_cloudfront_distribution.website.domain_name
}
