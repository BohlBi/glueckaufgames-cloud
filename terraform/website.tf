# Inhalte aus website/ in den primären Bucket laden.
# Die Replikation kopiert sie automatisch nach Irland.

locals {
  website_dir = "${path.module}/../website"

  content_types = {
    html = "text/html; charset=utf-8"
    css  = "text/css; charset=utf-8"
    js   = "application/javascript"
    png  = "image/png"
    jpg  = "image/jpeg"
    svg  = "image/svg+xml"
    ico  = "image/x-icon"
  }
}

resource "aws_s3_object" "website" {
  for_each = fileset(local.website_dir, "**")

  bucket       = module.storage.primary_bucket_id
  key          = each.value
  source       = "${local.website_dir}/${each.value}"
  etag         = filemd5("${local.website_dir}/${each.value}")
  content_type = lookup(local.content_types, reverse(split(".", each.value))[0], "application/octet-stream")

  depends_on = [module.storage]
}
