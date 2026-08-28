output "app_storage_id" {
  value = module.app_storage.storage_account_id
}

output "app_storage_name" {
  value = module.app_storage.storage_account_name
}

output "app_blob_endpoint" {
  value = module.app_storage.primary_blob_endpoint
}