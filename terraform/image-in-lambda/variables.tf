variable "name" {
  type        = string
  description = "The name of the service"
}

###############################################################################
# ECR

variable "repository_name" {
  type        = string
  description = "The name of the image repo to use"
}

variable "repository_url" {
  type        = string
  description = "The URL of the image to use"
}

###############################################################################
# API Gateway

variable "rest_api_execution_arn" {
  type        = string
  description = "The execution ARN of the API Gateway"
}

variable "rest_api_id" {
  type        = string
  description = "The ID of the API Gateway"
}

variable "parent_id" {
  type        = string
  description = "The starting path for the service"
}
