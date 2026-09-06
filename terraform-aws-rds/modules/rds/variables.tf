variable "db_identifier"{
    type= string
}

variable "db_name"{
    type= string
}

variable "db_username"{
    type= string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "security_group_name"{
    type = string
    default = "todo-rds-sg"
}

variable "db_port"{
    type = number
    default = 5432
}