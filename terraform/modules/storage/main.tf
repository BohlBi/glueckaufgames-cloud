# -----------------------------------------------------------------------------
# Zwei private Buckets: primär in Frankfurt, Replikat in Irland.
# Jede Änderung im primären Bucket wird automatisch nach Irland repliziert.
# -----------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.replica]
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  account_id   = data.aws_caller_identity.current.account_id
  primary_name = "${var.project}-website-${local.account_id}"
  replica_name = "${var.project}-website-replica-${local.account_id}"
}

# --- Primärer Bucket (Frankfurt) ---------------------------------------------

resource "aws_s3_bucket" "primary" {
  #checkov:skip=CKV_AWS_18:Zugriffsprotokolle würden zusätzliche Kosten verursachen; Zugriffe laufen ausschließlich über CloudFront.
  #checkov:skip=CKV_AWS_145:SSE-S3 statt KMS, um KMS-Kosten im 10-USD-Budget zu vermeiden.
  #checkov:skip=CKV2_AWS_62:Ereignisbenachrichtigungen werden nicht benötigt.
  bucket = local.primary_name
}

resource "aws_s3_bucket_ownership_controls" "primary" {
  bucket = aws_s3_bucket.primary.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "primary" {
  bucket = aws_s3_bucket.primary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "alte-versionen-aufraeumen"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.primary]
}

# --- Replikat (Irland) --------------------------------------------------------

resource "aws_s3_bucket" "replica" {
  #checkov:skip=CKV_AWS_18:Zugriffsprotokolle würden zusätzliche Kosten verursachen; Zugriffe laufen ausschließlich über CloudFront.
  #checkov:skip=CKV_AWS_145:SSE-S3 statt KMS, um KMS-Kosten im 10-USD-Budget zu vermeiden.
  #checkov:skip=CKV2_AWS_62:Ereignisbenachrichtigungen werden nicht benötigt.
  #checkov:skip=CKV_AWS_144:Dieser Bucket ist selbst das Replikat.
  provider = aws.replica
  bucket   = local.replica_name
}

resource "aws_s3_bucket_ownership_controls" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  rule {
    id     = "alte-versionen-aufraeumen"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.replica]
}

# --- Replikation Frankfurt -> Irland -----------------------------------------

data "aws_iam_policy_document" "replication_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "replication" {
  name               = "${var.project}-s3-replication"
  assume_role_policy = data.aws_iam_policy_document.replication_trust.json
}

data "aws_iam_policy_document" "replication" {
  statement {
    actions   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
    resources = [aws_s3_bucket.primary.arn]
  }

  statement {
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    resources = ["${aws_s3_bucket.primary.arn}/*"]
  }

  statement {
    actions   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
    resources = ["${aws_s3_bucket.replica.arn}/*"]
  }
}

resource "aws_iam_role_policy" "replication" {
  name   = "replicate-website"
  role   = aws_iam_role.replication.id
  policy = data.aws_iam_policy_document.replication.json
}

resource "aws_s3_bucket_replication_configuration" "primary_to_replica" {
  bucket = aws_s3_bucket.primary.id
  role   = aws_iam_role.replication.arn

  rule {
    id     = "website-nach-irland"
    status = "Enabled"

    filter {}

    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.primary,
    aws_s3_bucket_versioning.replica,
  ]
}
