resource "aws_api_gateway_resource" "root" {
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_id
  path_part   = var.name
}

resource "aws_api_gateway_method" "proxyMethod" {
   rest_api_id   = var.rest_api_id
   resource_id   = aws_api_gateway_resource.root.id
   http_method   = "ANY"
   authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
   rest_api_id = var.rest_api_id
   resource_id = aws_api_gateway_method.proxyMethod.resource_id
   http_method = aws_api_gateway_method.proxyMethod.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.main.invoke_arn
}
