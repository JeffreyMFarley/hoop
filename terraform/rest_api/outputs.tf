output "main_url" {
  value = "https://${aws_route53_record.main.fqdn}/"
}

output "rest_api_id" {
  value = aws_api_gateway_rest_api.main.id
}

output "root_id" {
  value = aws_api_gateway_rest_api.main.root_resource_id
}

output "version_path_id" {
  value = aws_api_gateway_resource.v1.id
}

output "rest_api_execution_arn" {
  value = aws_api_gateway_rest_api.main.execution_arn
}
