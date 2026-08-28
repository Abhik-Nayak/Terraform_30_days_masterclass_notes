terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
}

provider "aws"{
    region = "ap-south-1"
}

module "app_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "abhik-day4-app-bucket"
  environment = "dev"
}

# The power of modules: call the same one multiple times with different inputs.

 module "logs_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "abhik-day4-logs-bucket"
  environment = "prod"
}

module "backups_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "abhik-day4-backups-bucket"
  environment = "prod"
}