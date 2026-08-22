# Try to output a sensitive variable — Terraform will hide the value
output "password_check" {
  description = "This will be masked in output"
  value       = var.db_password
  sensitive   = true          # required when value comes from a sensitive var
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.demo.arn
}

output "bucket_region" {
  description = "Region where bucket lives"
  value       = var.region
}