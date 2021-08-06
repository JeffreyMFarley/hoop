output "endpoint" {
  value = "https://${aws_route53_record.main.fqdn}/"
}

output "cloudfront_id" {
  value = aws_cloudfront_distribution.main.id
}
