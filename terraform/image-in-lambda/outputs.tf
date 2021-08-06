output "service_path" {
  value       = aws_api_gateway_resource.root.path
  description = "The path within API Gateway to this service"
}
