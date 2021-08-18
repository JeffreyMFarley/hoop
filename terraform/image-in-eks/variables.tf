variable "name" {
  type        = string
  description = "The name of the service"
}

###############################################################################
# Load Balancer

variable "app_port" {
  type        = number
  description = "Application port (the service listens on)"
}

variable "host_port" {
  type        = number
  description = "Host port (the port used by the load balancer)"
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
# ECR

variable "repository_url" {
  type        = string
  description = "The URL of the image to use"
}

###############################################################################
# Database

variable "db_host" {
  type        = string
  default     = ""
  description = "The endpoint of the database"
}

variable "db_name" {
  type        = string
  default     = ""
  description = "The database to connect to"
}

variable "db_user" {
  type        = string
  default     = ""
  description = "The user to conect with"
}

variable "db_password" {
  type        = string
  default     = ""
  description = "The password for the user"
}
