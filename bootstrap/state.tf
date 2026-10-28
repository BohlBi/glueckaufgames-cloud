# -----------------------------------------------------------------------------
# S3-Bucket für den Terraform-State
# Privat, versioniert, verschlüsselt, nur per TLS erreichbar.
# Das Locking erfolgt direkt in S3 (use_lockfile), eine DynamoDB-Tabelle ist
# seit Terraform 1.11 nicht mehr nötig.
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

locals {
  account_id        = data.aws_caller_identity.current.account_id
  state_bucket_name = "${var.project}-tfstate-${local.account_id}"
}

resource "aws_s3_bucket" "state" {
  #checkov:skip=CKV_AWS_144:Cross-Region-Replikation für den State ist bei diesem Projektumfang unverhältnismäßig; Versionierung schützt vor Datenverlust.
  #checkov:skip=CKV_AWS_18:Zugriffsprotokolle würden einen weiteren Bucket und Kosten verursachen; Zugriffe sind über CloudTrail nachvollziehbar.
  #checkov:skip=CKV_AWS_145:SSE-S3 (AES-256) statt KMS, um KMS-Kosten im 10-USD-Budget zu vermeiden.
  #checkov:skip=CKV2_AWS_62:Ereignisbenachrichtigungen werden für den State nicht benötigt.
  bucket = local.state_bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "alte-state-versionen-aufraeumen"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.state]
}

# Verbindungen ohne TLS (HTTP) werden grundsätzlich abgelehnt.
data "aws_iam_policy_document" "state_tls_only" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state_tls_only.json

  depends_on = [aws_s3_bucket_public_access_block.state]
}
