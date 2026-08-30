terraform {
    required_providers{
        aws = {
        source  = "hashicorp/aws"
        version = "~> 5.92"
        }
    }

    backend "s3"{
        bucket = "abhik-day6-terraform-state"
        key = "dev/app/terraform.tfstate"
        region="ap-south-1"
        dynamodb_table = "abhik-day6-terraform-locks"
        encrypt = true
    }
}

provider "aws"{
    region ="ap-south-1"
}

resource "aws_s3_bucket" "app"{
    bucket = "abhik-day6-app-bucket"

    tags={
        Environment = "dev"
        ManagedBy= "terraform"
        Day = "6"
    }
}