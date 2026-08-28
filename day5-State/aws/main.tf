terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "app" {
  bucket = "abhik-day5-app-bucket"

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Day         = "5"
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "abhik-day5-logs-bucket"

  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
    Day         = "5"
  }
}
