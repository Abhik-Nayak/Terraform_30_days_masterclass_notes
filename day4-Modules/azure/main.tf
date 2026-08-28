terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 5.0"
    }
  }
}

provider "azurerm" {
    features {}
    subscription_id = "f56b6379-0e9a-40e5-9e06-4e62643ed254"
}

resource "azurerm_resource_group" "this" {
  name     = "day4-modules-rg"
  location = "centralindia"
}

# Call our module -- like calling a function
module "app_storage" {
  source               = "./modules/storage-account"
  storage_account_name = "abhikday4appstore"
  resource_group_name  = azurerm_resource_group.this.name
  location             = azurerm_resource_group.this.location
  environment          = "dev"
}