variable "name" {
  type        = string
  description = "The system name of the database"
}

variable "db_name" {
  type        = string
  description = "The name of the database inside instance"
  default     = "postgres"
}

variable "db_username" {
  type        = string
  description = "The master database user"
  default     = "postgres"
}

# VPC

variable "developer_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks of the developers"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "IDs for public subnets"
}

variable "private_subnet_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks for private subnets"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "IDs for private subnets"
}

variable "vpc_id" {
  type        = string
  description = "The id for the VPC where the ECS container instance should be deployed"
}
