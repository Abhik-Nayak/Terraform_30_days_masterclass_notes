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

data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-day3-learn-bucket"

  tags = {
    Name        = "Day3 demo"
    Environmant = "dev"
  }

  lifecycle {
    prevent_destroy = false   # safety: can't accidentally destroy this if it is "ture"
    ignore_changes  = [tags] # Terraform won't care if tags change outside
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "abhik-day3-logs-bucket"

  tags = {
    Name = "Logs Bucket"
  }
}

resource "aws_s3_object" "readme" {
  bucket  = aws_s3_bucket.my_bucket.id
  key     = "readme.txt"
  content = " This bucket was created by Terraform on Day 3"
}

# create bucket using multi
resource "aws_s3_bucket" "multi" {
  count  = 3
  bucket = "abhik-day-3-multi-${count.index}"

  tags = {
    Name = "Bucket ${count.index}"
  }
}

# Create Bucket using for_each(etter that multi)
resource "aws_s3_bucket" "env_buckets" {
  for_each = toset(["dev", "staging", "prod"])
  bucket   = "abhik-day3-${each.value}-data"

  tags = {
    Environmant = each.value
  }

}
