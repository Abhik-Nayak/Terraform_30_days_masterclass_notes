variable "aws_region"{
    type= string
    default = "ap-south-1"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_username" {
  type = string
}