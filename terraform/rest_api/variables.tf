variable "name" {
  type        = string
  description = "The name of the API Gateway"
}

variable "api_domain_name" {
  type        = string
  description = "The domain name for the API"
}

variable "domain_name" {
  type        = string
  description = "The top-level domain name"
}

variable "region" {
  type = string
  description = "The AWS region where resources have been deployed"
}
