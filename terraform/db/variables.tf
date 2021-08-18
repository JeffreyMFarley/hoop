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

variable "inbound_subnets" {
  type        = list(string)
  description = "CIDR blocks of VPC subnets that will call the DB"
}

variable "subnet_group_name" {
  type        = string
  description = "The name of the database subnet group"
}

variable "vpc_id" {
  type        = string
  description = "The id for the VPC where the database should be deployed"
}
