resource "aws_api_gateway_rest_api" "main" {
  name        = var.name
  description = "REST API for ${var.name}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# NOTE: The deployment, stage and base-path mapping live in the root module
# (see all.tf). They must be created *after* every service's methods and
# integrations, which in turn depend on this module — keeping them here would
# create a dependency cycle and snapshot an empty API.

resource "aws_api_gateway_resource" "v1" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "v1"
}
