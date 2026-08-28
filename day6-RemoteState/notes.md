# Day 6: Remote State

## Why Remote State?

- Local state works for learning, but **fails in teams**:
  - No shared access -- each team member has their own copy
  - No locking -- concurrent `terraform apply` can corrupt state
  - No encryption -- secrets stored in plain text on disk
- Remote state solves all three problems

## S3 + DynamoDB Backend (AWS)

The most common remote backend for AWS users.

### Step 1: Create the Backend Resources

These resources must be created **before** configuring the backend (chicken-and-egg problem). Create them manually or with a separate Terraform config.

```hcl
# backend-setup/main.tf -- run this first, separately

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-project-terraform-state"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
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

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

### Step 2: Configure the Backend

```hcl
# main.tf -- your actual project

terraform {
  backend "s3" {
    bucket         = "my-project-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

### Step 3: Initialize

```bash
terraform init
```

Terraform detects the backend change and asks to migrate existing local state to S3.

## Backend Configuration Breakdown

| Parameter        | Purpose                                      |
|------------------|----------------------------------------------|
| `bucket`         | S3 bucket name for storing state             |
| `key`            | Path within the bucket (e.g., `prod/terraform.tfstate`) |
| `region`         | AWS region of the S3 bucket                  |
| `dynamodb_table` | DynamoDB table for state locking             |
| `encrypt`        | Enable server-side encryption                |

## State Locking with DynamoDB

- When someone runs `terraform plan` or `apply`, Terraform writes a lock entry to DynamoDB
- If another user tries to run at the same time, they get a lock error:

```
Error: Error acquiring the state lock
Lock Info:
  ID:        abcd-1234-efgh
  Who:       user@hostname
  Operation: OperationTypeApply
```

- The lock is released automatically when the operation finishes
- Force unlock only if a process crashed and left a stale lock:

```bash
terraform force-unlock <LOCK_ID>
```

## `terraform_remote_state` Data Source

Read outputs from **another** Terraform project's state. Useful for sharing infrastructure info across projects.

```hcl
# In project B, read state from project A
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "my-project-terraform-state"
    key    = "network/terraform.tfstate"
    region = "us-east-1"
  }
}

# Use the outputs from project A
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = data.terraform_remote_state.network.outputs.public_subnet_id
}
```

For this to work, project A must expose values as `output` blocks:

```hcl
# In project A
output "public_subnet_id" {
  value = aws_subnet.public.id
}
```

## Migrating Local State to Remote

If you already have a local `terraform.tfstate` and add a backend block:

```bash
terraform init

# Terraform prompts:
# "Do you want to copy existing state to the new backend?"
# Answer: yes
```

After migration:
- State is now in S3
- Local `terraform.tfstate` becomes empty or is removed
- All future operations read/write from S3

## Migrating Remote Back to Local

Remove the `backend` block from config, then:

```bash
terraform init -migrate-state
```

## Best Practices

1. **Enable versioning** on the S3 bucket -- recover from accidental state corruption
2. **Enable encryption** -- state contains secrets
3. **Block public access** on the S3 bucket
4. **Use one state file per environment** -- separate keys for dev/staging/prod:
   ```
   key = "dev/terraform.tfstate"
   key = "staging/terraform.tfstate"
   key = "prod/terraform.tfstate"
   ```
5. **Limit access** with IAM policies -- not everyone needs state access
6. **Never store backend resources in the same state they configure** -- use a separate bootstrap project

## Key Takeaways

1. Remote state enables team collaboration with shared access and locking
2. S3 + DynamoDB is the standard AWS backend pattern
3. `terraform_remote_state` lets projects share data through outputs
4. Always enable versioning and encryption on state buckets
5. Migrate with `terraform init` -- it handles the transfer automatically

---

## Follow-Up: Learn by Doing (Step-by-Step)

### Step 1 -- Create the Backend Infrastructure

First, create the S3 bucket and DynamoDB table that will store your state. This is a separate Terraform project (the "bootstrap").

```
day6/
  aws/
    backend-setup/
      main.tf
      outputs.tf
    app/
      main.tf
      outputs.tf
```

```hcl
# ---- backend-setup/main.tf ----

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

resource "aws_s3_bucket" "terraform_state" {
  bucket = "abhik-day6-terraform-state"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
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

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
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
```

```bash
cd backend-setup
terraform init
terraform apply
# Note the bucket name and table name from the output
```

---

### Step 2 -- Configure a Project to Use Remote State

Now create a separate project that uses the S3 backend.

```hcl
# ---- app/main.tf ----

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  backend "s3" {
    bucket         = "abhik-day6-terraform-state"
    key            = "dev/app/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "abhik-day6-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "app" {
  bucket = "abhik-day6-app-bucket"

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Day         = "6"
  }
}
```

```bash
cd app
terraform init
# Notice: "Successfully configured the backend 's3'!"
# No local terraform.tfstate file is created

terraform apply
terraform state list
# State is now in S3, not on your local disk
```

---

### Step 3 -- Verify State is in S3

```bash
# Check that no local state file exists
ls terraform.tfstate
# File not found (it's in S3 now!)

# Verify in AWS
aws s3 ls s3://abhik-day6-terraform-state/dev/app/
# terraform.tfstate should appear
```

---

### Step 4 -- Test State Locking

Open two terminals and try to run `terraform plan` in both at the same time:

```bash
# Terminal 1
terraform plan

# Terminal 2 (run while Terminal 1 is still planning)
terraform plan
# Error: Error acquiring the state lock
# This proves DynamoDB locking is working!
```

---

### Step 5 -- Use `terraform_remote_state` to Read Another Project's Outputs

Add outputs to the app project so another project can read them:

```hcl
# ---- app/outputs.tf ----

output "app_bucket_arn" {
  value = aws_s3_bucket.app.arn
}

output "app_bucket_id" {
  value = aws_s3_bucket.app.id
}
```

```bash
terraform apply    # outputs are now stored in the remote state
```

Now imagine a second project that needs the app bucket ARN:

```hcl
# ---- (another project) main.tf ----

data "terraform_remote_state" "app" {
  backend = "s3"

  config = {
    bucket = "abhik-day6-terraform-state"
    key    = "dev/app/terraform.tfstate"
    region = "ap-south-1"
  }
}

# Use the output from the app project
output "app_bucket_from_remote" {
  value = data.terraform_remote_state.app.outputs.app_bucket_arn
}
```

---

### Step 6 -- Migrate Local State to Remote

If you have a project with local state and want to move it to S3:

```bash
# 1. Add the backend "s3" block to your terraform {} block
# 2. Run:
terraform init

# Terraform asks:
# "Do you want to copy existing state to the new backend?"
# Type: yes

# 3. Verify
terraform state list   # same resources, now from S3
ls terraform.tfstate   # local file is now empty or gone
```

---

### Step 7 -- Inspect State Versions in S3

```bash
# S3 versioning lets you recover old state
aws s3api list-object-versions \
  --bucket abhik-day6-terraform-state \
  --prefix dev/app/terraform.tfstate

# Each terraform apply creates a new version
# You can restore an older version if state gets corrupted
```

---

### Step 8 -- Clean Up

```bash
# Destroy the app resources first
cd app
terraform destroy

# Then destroy the backend infrastructure
cd ../backend-setup
# Remove the prevent_destroy lifecycle rule first, then:
terraform destroy
```

---

## Done?

After completing all 8 steps you understand:
- How to create backend infrastructure (S3 bucket + DynamoDB table) separately
- How to configure a project to use the S3 backend
- State is stored remotely -- no local `terraform.tfstate` file
- DynamoDB locking prevents concurrent operations
- `terraform_remote_state` lets projects share outputs across state files
- How to migrate existing local state to remote with `terraform init`
- S3 versioning protects against state corruption
