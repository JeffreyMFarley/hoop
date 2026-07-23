resource "aws_s3_bucket" "main" {
  bucket        = var.name
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  index_document {
    suffix = "index.html"
  }
}

# Public-read static site: object ownership + public access block must permit
# ACLs before the bucket ACL and public policy can be applied (provider v4+).
resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "main" {
  depends_on = [
    aws_s3_bucket_ownership_controls.main,
    aws_s3_bucket_public_access_block.main,
  ]

  bucket = aws_s3_bucket.main.id
  acl    = "public-read"
}

# Creates policy to allow public access to the S3 bucket
resource "aws_s3_bucket_policy" "update_web_root_bucket_policy" {
  depends_on = [aws_s3_bucket_public_access_block.main]

  bucket = aws_s3_bucket.main.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "PolicyForWebsiteEndpointsPublicContent",
  "Statement": [
    {
      "Sid": "PublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "${aws_s3_bucket.main.arn}/*",
        "${aws_s3_bucket.main.arn}"
      ]
    }
  ]
}
POLICY
}
