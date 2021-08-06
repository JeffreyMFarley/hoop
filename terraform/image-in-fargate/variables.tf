variable "name" {
  type        = string
  description = "The name of the service"
}

variable "app_port" {
  type        = number
  description = "Application port (the service listens on)"
}

variable "host_port" {
  type        = number
  description = "Host port (the port used by the load balancer)"
}

variable "cpu" {
  type        = number
  default     = 1024
  description = "Fargate cpu allocation"
}

variable "memory" {
  type        = number
  default     = 2048
  description = "Fargate memory allocation"
}

variable "environment" {
  type        = list
  default     = []
  description = "An array of {name: x, value: y}"
}

variable "secrets" {
  type        = list
  default     = []
  description = "An array of {name: x, valueFrom: arn}"
}

###############################################################################
# Overall

variable "region" {
  type = string
  description = "The AWS region where resources have been deployed"
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
# Api Gateway

variable "rest_api_id" {
  type        = string
  description = "The ID of the API Gateway"
}

variable "parent_id" {
  type        = string
  description = "The starting path for the service"
}

###############################################################################
# VPC

variable "cluster_id" {
  type        = string
  description = "Cluster ID"
}

variable "security_group_id" {
  type        = string
  description = "The ID of the security group for the ECS tasks"
}

variable "subnet_ids" {
  type        = list(string)
  description = "IDs for private subnets"
}

variable "subnet_cidr_blocks" {
  type        = list(string)
  description = "The CIDR blocks for private subnets"
}

variable "vpc_id" {
  type        = string
  description = "The id for the VPC where the ECS container instance should be deployed"
}
