variable "aws_region"{
    description = "The AWS region to deploy resources in."
    type        = string
    default     = "us-east-1"
}

variable "app_vpc_cidr"{
    description = "The CIDR block for the VPC."
    type        = string
    default     = "10.0.0.0/16"
}

variable "database_vpc_cidr"{
    description = "The CIDR block for the database VPC."
    type        = string
    default     = "10.1.0.0/16"
}

variable "app_subnet_cidr"{
    description = "The CIDR block for the application subnet."
    type        = string
    default     = "10.0.1.0/24"
}

variable "database_subnet_cidr" {
  description = "Subnet CIDR for the database VPC"
  type        = string
  default     = "10.1.1.0/24"
}