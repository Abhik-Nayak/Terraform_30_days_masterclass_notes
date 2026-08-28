output "storage_account_id" {
  description = "ID of the created storage account"
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the created storage account"
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint URL"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_access_key" {
  description = "Primary access key (sensitive)"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}