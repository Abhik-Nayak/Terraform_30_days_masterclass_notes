terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
  required_version = ">= 1.2"
}
provider "aws" {
  alias = "mumbai"
  region = "ap-south-1"
}

resource "aws_s3_bucket" "demo" {
  bucket = "my-day1-demo-bucket-12345"
}