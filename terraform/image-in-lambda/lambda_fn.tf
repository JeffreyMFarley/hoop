data "aws_ecr_image" "service_image" {
  repository_name = var.repository_name
  image_tag       = "latest"
}

resource "aws_lambda_function" "main" {
   function_name = "${var.name}_container"
   image_uri     = "${var.repository_url}:latest"
   role          = aws_iam_role.fn_role.arn
   package_type  = "Image"

   depends_on = [data.aws_ecr_image.service_image]
}

 # IAM role which dictates what other AWS services the Lambda function
 # may access.
resource "aws_iam_role" "fn_role" {
   name = "${var.name}-lambda-role"

   assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_lambda_permission" "apigw" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.main.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${var.rest_api_execution_arn}/*/*"
}
