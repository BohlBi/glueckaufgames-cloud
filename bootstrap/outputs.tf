output "state_bucket" {
  description = "Name des S3-Buckets für den Terraform-State (für terraform init -backend-config)."
  value       = aws_s3_bucket.state.bucket
}

output "github_plan_role_arn" {
  description = "ARN der Rolle für terraform plan (GitHub-Variable AWS_PLAN_ROLE_ARN)."
  value       = one(aws_iam_role.plan[*].arn)
}

output "github_apply_role_arn" {
  description = "ARN der Rolle für terraform apply (GitHub-Variable AWS_APPLY_ROLE_ARN)."
  value       = one(aws_iam_role.apply[*].arn)
}
