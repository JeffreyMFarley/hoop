output "arn" {
  value = aws_s3_bucket.main.arn
}

output "id" {
  value = aws_s3_bucket.main.id
}

output "name" {
  value = aws_s3_bucket.main.bucket
}

output "website_endpoint" {
  value = aws_s3_bucket.main.website_endpoint
}
