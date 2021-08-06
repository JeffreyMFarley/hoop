# :+1: to https://medium.com/runatlantis/hosting-our-static-site-over-ssl-with-s3-acm-cloudfront-and-terraform-513b799aec0f

data "aws_acm_certificate" "cert" {
  domain   = "*.${var.domain_name}"
  statuses = ["ISSUED"]
}

resource "aws_cloudfront_distribution" "main" {
  // origin is where CloudFront gets its content from.
  origin {
    // We need to set up a "custom" origin because otherwise CloudFront won't
    // redirect traffic from the root domain to the www domain
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    domain_name = var.website_endpoint
    origin_id   = var.bucket_and_host_name
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    // This needs to match the `origin_id` above.
    target_origin_id       = var.bucket_and_host_name
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  // Here we're ensuring we can hit this distribution using our domain name
  // rather than the domain name CloudFront gives us.
  aliases = [var.bucket_and_host_name]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.cert.arn
    ssl_support_method  = "sni-only"
  }
}
