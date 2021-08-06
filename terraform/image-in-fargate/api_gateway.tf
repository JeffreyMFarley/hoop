resource "aws_api_gateway_resource" "root" {
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_id
  path_part   = var.name
}

resource "aws_api_gateway_method" "rootMethod" {
   rest_api_id   = var.rest_api_id
   resource_id   = aws_api_gateway_resource.root.id
   http_method   = "ANY"
   authorization = "NONE"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = var.rest_api_id
  parent_id   = aws_api_gateway_resource.root.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxyMethod" {
   rest_api_id   = var.rest_api_id
   resource_id   = aws_api_gateway_resource.proxy.id
   http_method   = "ANY"
   authorization = "NONE"

   request_parameters = {
     "method.request.path.proxy" = true
   }
}

resource "aws_api_gateway_vpc_link" "this" {
  name = "vpc-link-${var.name}"
  target_arns = [aws_lb.nlb.arn]
}

resource "aws_api_gateway_integration" "root" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_method.rootMethod.resource_id
  http_method = aws_api_gateway_method.rootMethod.http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${aws_lb.nlb.dns_name}:${var.host_port}/"

  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.this.id
}

resource "aws_api_gateway_integration" "to_vpc" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_method.proxyMethod.resource_id
  http_method = aws_api_gateway_method.proxyMethod.http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${aws_lb.nlb.dns_name}:${var.host_port}/{proxy}"

  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.this.id

  request_parameters = {
      "integration.request.path.proxy" = "method.request.path.proxy"
  }
}
