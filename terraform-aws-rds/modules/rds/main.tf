# find existing security group by name
data "aws_security_group" "rds"{
    filter {
        name = "group-name"
        values = [var.security_group_name]
    }
}

# then create RDS
resource "aws_db_instance" "this" {
    identifier = var.db_identifier

    allocated_storage = 20
    
    engine = "postgres"
    engine_version = "17"

    instance_class = "db.t4g.micro"

    db_name = var.db_name
    username = var.db_username
    password = var.db_password
    port = var.db_port

    vpc_security_group_ids = [data.aws_security_group.rds.id]
      publicly_accessible = false

    backup_retention_period = 7

    multi_az = false

    skip_final_snapshot = true
}
