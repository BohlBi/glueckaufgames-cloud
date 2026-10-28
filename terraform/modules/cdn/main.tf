# -----------------------------------------------------------------------------
# CloudFront liefert die Website weltweit aus.
# - Zugriff auf die Buckets nur über Origin Access Control (OAC)
# - Origin Group: fällt Frankfurt aus, wird automatisch Irland genutzt
# - nur HTTPS, Security-Header für jede Antwort
# -----------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.replica]
    }
  }
}

locals {
  primary_origin_id = "s3-frankfurt"
  replica_origin_id = "s3-irland"
  origin_group_id   = "s3-failover"

  # Von AWS verwaltete Cache-Richtlinie "Managed-CachingOptimized"
  caching_optimized_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
}

resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.project}-s3-oac"
  description                       = "Signierter Zugriff von CloudFront auf die Website-Buckets"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_response_headers_policy" "security" {
  name = "${var.project}-security-headers"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    content_security_policy {
      content_security_policy = "default-src 'self'; img-src 'self' data:; object-src 'none'; base-uri 'self'; frame-ancestors 'none'"
      override                = true
    }
  }
}

resource "aws_cloudfront_distribution" "website" {
  #checkov:skip=CKV_AWS_68:WAF bewusst verworfen (Kosten); statische Seite ohne Formulare, Shield Standard schützt vor DDoS.
  #checkov:skip=CKV2_AWS_47:Siehe CKV_AWS_68, kein WAF.
  #checkov:skip=CKV_AWS_86:Zugriffsprotokolle würden zusätzliche Kosten verursachen; Standard-Metriken in CloudWatch reichen.
  #checkov:skip=CKV_AWS_174:Ohne eigene Domain nutzt CloudFront das Standardzertifikat; die TLS-Mindestversion ist dann nicht einstellbar.
  #checkov:skip=CKV2_AWS_42:Keine eigene Domain, daher kein eigenes Zertifikat.
  #checkov:skip=CKV_AWS_374:Keine Geo-Beschränkung, Besucher kommen aus der ganzen Welt.
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2and3"
  price_class         = var.price_class
  default_root_object = "index.html"
  comment             = "${var.project} Website"

  origin {
    origin_id                = local.primary_origin_id
    domain_name              = var.primary_bucket_domain
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  origin {
    origin_id                = local.replica_origin_id
    domain_name              = var.replica_bucket_domain
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  origin_group {
    origin_id = local.origin_group_id

    failover_criteria {
      status_codes = [403, 404, 500, 502, 503, 504]
    }

    member {
      origin_id = local.primary_origin_id
    }

    member {
      origin_id = local.replica_origin_id
    }
  }

  default_cache_behavior {
    target_origin_id           = local.origin_group_id
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    compress                   = true
    cache_policy_id            = local.caching_optimized_policy_id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# --- Bucket-Richtlinien: nur diese Distribution darf lesen, nur per TLS -------

data "aws_iam_policy_document" "primary" {
  statement {
    sid       = "AllowCloudFrontRead"
    actions   = ["s3:GetObject"]
    resources = ["${var.primary_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website.arn]
    }
  }

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [var.primary_bucket_arn, "${var.primary_bucket_arn}/*"]

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

data "aws_iam_policy_document" "replica" {
  statement {
    sid       = "AllowCloudFrontRead"
    actions   = ["s3:GetObject"]
    resources = ["${var.replica_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website.arn]
    }
  }

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [var.replica_bucket_arn, "${var.replica_bucket_arn}/*"]

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

resource "aws_s3_bucket_policy" "primary" {
  bucket = var.primary_bucket_id
  policy = data.aws_iam_policy_document.primary.json
}

resource "aws_s3_bucket_policy" "replica" {
  provider = aws.replica
  bucket   = var.replica_bucket_id
  policy   = data.aws_iam_policy_document.replica.json
}
