# Terraform — Modular AWS RDS PostgreSQL

## 1. Requirements

```text
Region              : ap-south-1
RDS Engine          : PostgreSQL
Database             : appdb
Username             : app_admin
Port                 : 5432
Existing SG          : rds-security-gp
RDS Identifier       : todo-db
```

> Do not hard-code the database password in Git/Terraform files.

---

## 2. Create Project

```bash
mkdir terraform-rds
cd terraform-rds

mkdir -p modules/rds
```

Structure:

```text
terraform-rds/
├── providers.tf
├── variables.tf
├── main.tf
├── outputs.tf
├── terraform.tfvars
├── .gitignore
│
└── modules/
    └── rds/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

# 3. Provider

### `providers.tf`

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.aws_region
}
```

**Why:** Configures Terraform to use AWS in `ap-south-1`.

---

# 4. Root Variables

### `variables.tf`

```hcl
variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "db_password" {
  type      = string
  sensitive = true
}
```

---

# 5. Terraform Variables

### `terraform.tfvars`

```hcl
aws_region  = "ap-south-1"
db_password = "YOUR_NEW_DATABASE_PASSWORD"
```

> Keep this file out of Git.

---

# 6. RDS Module Variables

### `modules/rds/variables.tf`

```hcl
variable "db_identifier" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "security_group_name" {
  type = string
}

variable "db_port" {
  type    = number
  default = 5432
}
```

---

# 7. RDS Module

### `modules/rds/main.tf`

First, find the **existing Security Group**:

```hcl
data "aws_security_group" "rds" {
  filter {
    name   = "group-name"
    values = [var.security_group_name]
  }
}
```

Then create RDS:

```hcl
resource "aws_db_instance" "this" {
  identifier = var.db_identifier

  engine         = "postgres"
  engine_version = "17"

  instance_class = "db.t4g.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = var.db_port

  vpc_security_group_ids = [
    data.aws_security_group.rds.id
  ]

  publicly_accessible = false

  backup_retention_period = 7

  multi_az = false

  skip_final_snapshot = true
}
```

### Important

We are **not creating a new Security Group**.

Terraform does:

```text
Existing SG
rds-security-gp
      ↓
data.aws_security_group.rds
      ↓
Security Group ID
      ↓
RDS
```

---

# 8. Module Outputs

### `modules/rds/outputs.tf`

```hcl
output "db_endpoint" {
  value = aws_db_instance.this.address
}

output "db_port" {
  value = aws_db_instance.this.port
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "db_username" {
  value = aws_db_instance.this.username
}

output "security_group_id" {
  value = data.aws_security_group.rds.id
}
```

---

# 9. Call the Module

### `main.tf`

```hcl
module "rds" {
  source = "./modules/rds"

  db_identifier = "todo-db"

  db_name     = "appdb"
  db_username = "app_admin"
  db_password = var.db_password

  security_group_name = "rds-security-gp"

  db_port = 5432
}
```

Module flow:

```text
main.tf
   ↓
module "rds"
   ↓
modules/rds
   ↓
Find existing SG
   ↓
Create PostgreSQL RDS
```

---

# 10. Root Outputs

### `outputs.tf`

```hcl
output "db_host" {
  value = module.rds.db_endpoint
}

output "db_port" {
  value = module.rds.db_port
}

output "db_name" {
  value = module.rds.db_name
}

output "db_username" {
  value = module.rds.db_username
}

output "security_group_id" {
  value = module.rds.security_group_id
}
```

---

# 11. Git Ignore

### `.gitignore`

```gitignore
.terraform/
*.tfstate
*.tfstate.*
terraform.tfvars
crash.log
```

---

# 12. Terraform Commands

## Initialize

```bash
terraform init
```

**Why:** Downloads the AWS provider and initializes Terraform.

---

## Format

```bash
terraform fmt -recursive
```

**Why:** Formats all Terraform files, including modules.

---

## Validate

```bash
terraform validate
```

**Why:** Checks Terraform configuration for errors.

---

## Plan

```bash
terraform plan
```

**Why:** Shows what Terraform will create/change.

Check that:

```text
data.aws_security_group.rds
```

is being read and that Terraform is **not creating another Security Group**.

---

## Apply

```bash
terraform apply
```

Then type:

```text
yes
```

**Why:** Creates the RDS infrastructure in AWS.

---

# 13. Get RDS Information

```bash
terraform output
```

Get only the hostname:

```bash
terraform output -raw db_host
```

Example:

```text
todo-db.xxxxxxxxx.ap-south-1.rds.amazonaws.com
```

---

# 14. Application `.env`

```env
PGHOST=todo-db.xxxxxxxxx.ap-south-1.rds.amazonaws.com
PGPORT=5432
PGDATABASE=appdb
PGUSER=app_admin
PGPASSWORD=YOUR_DATABASE_PASSWORD
PGSSL=true
```

---

# 15. Final Terraform Flow

```text
Terraform Root Module
        │
        ▼
    module "rds"
        │
        ▼
   RDS Module
        │
        ├── Find existing SG
        │       │
        │       └── rds-security-gp
        │
        └── Create PostgreSQL RDS
                    │
                    ▼
              RDS Endpoint
                    │
                    ▼
               Application
```

## Command Order

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
terraform output
```
