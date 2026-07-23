output "service_path" {
  value       = aws_api_gateway_resource.root.path
  description = "The path within API Gateway to this service"
}

# Hash of this service's API Gateway routes, so the root deployment redeploys
# whenever they change.
output "redeploy_hash" {
  value = sha1(jsonencode([
    aws_api_gateway_resource.root.id,
    aws_api_gateway_method.proxyMethod.id,
    aws_api_gateway_integration.lambda.id,
  ]))
}
