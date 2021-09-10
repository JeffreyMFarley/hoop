variable "account_id" {
  type        = string
  description = "The AWS account ID"
}

variable "region" {
  type        = string
  description = "The main Amazon region where resources will be deployed"
}

variable "name" {
  type        = string
  description = "The name of the project"
}

variable "domain_name" {
  type        = string
  description = "The top-level domain name"
}

variable "developer_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks of the developers"
}
