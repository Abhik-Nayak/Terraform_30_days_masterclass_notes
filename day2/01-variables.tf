variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "bucket_name"{
    description = "Name of the S3 Bucket"
    type = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "terraform-30days"
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  # validation block = custom rule that Terraform checks BEFORE plan/apply
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# add secret
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}