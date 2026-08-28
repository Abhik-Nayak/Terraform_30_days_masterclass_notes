terraform {
    required_providers {
      aws={
        source = "hashicorp/aws"
        version = "~> 5.92"
      }
    }
}

provider "aws"{
    region = "ap-south-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "abhik-day6-terraform-state"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_versioning" "enabled"{
    bucket = aws_s3_bucket.terraform_state.id

    versioning_configuration{
        status = "Enabled"
    }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}


resource "aws_s3_bucket_public_access_block" "public_access"{
    bucket = aws_s3_bucket.terraform_state.id
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "abhik-day6-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
