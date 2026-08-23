variable "bucket_name" {
  description = "Name ofthe S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment tag (dev,stagging, prod)"
  type        = string
  default     = "dev"
}
