variable "bucket_and_host_name" {
  type        = string
  description = "The host name for the bucket.  Must match a domain name for Route 53 integration"
}

variable "domain_name" {
  type        = string
  description = "The top-level domain name"
}

variable "website_endpoint" {
  type        = string
  description = "The S3 endpoint"
}
