module "rds" {
    source = "./modules/rds"

    db_identifier = "todo-db"

    db_name = "appdb"
    db_username = "postgres"
    db_password = var.db_password

    security_group_name = "todo-rds-sg"

    db_port = 5432
}