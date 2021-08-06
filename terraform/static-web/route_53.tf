data "aws_route53_zone" "zone" {
  name = var.domain_name
}

resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.bucket_and_host_name
  type    = "A"

  alias {
      name                   = aws_cloudfront_distribution.main.domain_name
      zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
      evaluate_target_health = false
  }
}
