output "app_bucket_arn" {
  value = module.app_bucket.bucket_arn
}

output "app_bucket_id" {
  value = module.app_bucket.bucket_id
}

output "logs_bucket_arn" {
  value = module.logs_bucket.bucket_arn
}

output "backups_bucket_arn" {
  value = module.backups_bucket.bucket_arn
}
