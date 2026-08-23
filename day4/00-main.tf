terraform{
    required_providers {
      aws ={
        source = "hashicorp/aws"
        version = "~> 5.92"
      }
    }
}

provider "aws"{
    region = "ap-south-1"
}

module "app_bucket"{
    source = "./02-modules"
    bucket_name = "abhik-day4-app-bucket"
    environment = "dev"
}

module "logs_bucket"{
    source = "./02-modules"
    bucket_name = "abhik-day4-logs-bucket"
    environment = "dev"
}

module "backups_bucket"{
    source = "./02-modules"
    bucket_name = "abhik-day4-backups-bucket"
    environment = "prod"
}