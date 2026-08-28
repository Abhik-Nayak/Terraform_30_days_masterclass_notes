terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
  required_version = ">= 1.2"
}

provider "aws"{
    region = var.region
}

resource "aws_s3_bucket" "demo"{
    bucket = var.bucket_name
    tags = var.tags
}

