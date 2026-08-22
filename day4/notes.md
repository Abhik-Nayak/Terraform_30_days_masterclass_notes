# Day 4: Modules (80/20)

## What is a Module?

A module is a **folder of `.tf` files** used as a reusable unit. Every Terraform project is already a module (the "root module"). When you call another folder or a registry module, that's a "child module."

```
Why modules?
- DRY: write once, use in dev/staging/prod
- Encapsulation: hide complexity behind simple inputs/outputs
- Team sharing: publish to registry or Git for others to use
```

## The 3 Things That Matter

### 1. Module structure (it's just a folder)

```
modules/
  s3-bucket/
    main.tf          # resources
    variables.tf     # inputs (what the caller provides)
    outputs.tf       # outputs (what the caller gets back)
```

### 2. Call the module

```hcl
module "logs_bucket" {
  source = "./modules/s3-bucket"     # path to the module folder

  bucket_name = "my-app-logs"        # pass inputs as arguments
  environment = "prod"
}
```

### 3. Use the module's outputs

```hcl
# Access with: module.<name>.<output_name>
output "logs_bucket_arn" {
  value = module.logs_bucket.bucket_arn
}
```

---

## Module Sources

| Source | Example | Use when |
|--------|---------|----------|
| Local path | `"./modules/s3-bucket"` | Your own code, same repo |
| Terraform Registry | `"hashicorp/consul/aws"` | Community/official modules |
| GitHub | `"github.com/org/repo//modules/vpc"` | Team-shared modules |
| S3/GCS | `"s3::https://bucket/module.zip"` | Private module storage |

After changing the `source`, always run `terraform init` (or `terraform init -upgrade`).

---

## Module Inputs & Outputs

### Inputs = variables declared inside the module

```hcl
# ---- modules/s3-bucket/variables.tf ----

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}
```

The caller passes values like function arguments:

```hcl
module "logs_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "my-logs"          # required (no default)
  environment = "prod"             # optional (has default)
}
```

### Outputs = what the module exposes back

```hcl
# ---- modules/s3-bucket/outputs.tf ----

output "bucket_arn" {
  value = aws_s3_bucket.this.arn
}

output "bucket_id" {
  value = aws_s3_bucket.this.id
}
```

The caller accesses them with `module.<name>.<output>`:

```hcl
resource "aws_s3_bucket_policy" "logs_policy" {
  bucket = module.logs_bucket.bucket_id      # using module output
  # ...
}
```

---

## Root Module vs Child Module

| | Root Module | Child Module |
|--|------------|--------------|
| What is it | Your top-level `.tf` files | A folder called via `module {}` |
| Runs directly? | Yes (`terraform apply`) | No (only through its caller) |
| Has state? | Yes | No (resources stored in caller's state) |
| Variables set by | CLI, tfvars, env vars | The `module {}` block arguments |
| Outputs visible to | Terminal / other modules | Only the caller |

---

## Using Registry Modules

The Terraform Registry has pre-built modules for common patterns (VPC, EKS, RDS, etc.).

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"                          # always pin the version

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
}
```

```bash
terraform init      # downloads the module from registry
terraform plan
```

---

## Key Commands

```bash
terraform init               # download modules (required after adding/changing source)
terraform init -upgrade      # re-download modules even if cached
terraform plan               # preview (modules are transparent in plan output)
terraform apply              # create everything including module resources
terraform state list         # module resources show as: module.<name>.<resource>
terraform output             # root module outputs only
```

---

## Common Gotchas

- Forgot `terraform init` after adding a module? You get: `Module not installed`.
- Module resources appear in state as `module.logs_bucket.aws_s3_bucket.this` --
  you can't `terraform destroy` just a module; destroy its resources individually
  or remove the `module {}` block and apply.
- Changing `source` requires `terraform init` again -- Terraform doesn't auto-detect.
- Module outputs are NOT automatically exposed to the terminal.
  You must re-export them in the root module's `outputs.tf`.
- Registry modules without `version` will grab latest -- fine for experiments,
  dangerous in production. Always pin with `version = "~> X.Y"`.
- Local modules are loaded from disk every time. Registry/Git modules are cached
  in `.terraform/modules/` after `init`.

---

## Follow-Up: Learn by Doing (Step-by-Step)

### Step 1 -- Create a Local Module

Build a reusable S3 bucket module.

```
day4/
  main.tf
  outputs.tf
  modules/
    s3-bucket/
      main.tf
      variables.tf
      outputs.tf
```

```hcl
# ---- modules/s3-bucket/variables.tf ----

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment tag (dev, staging, prod)"
  type        = string
  default     = "dev"
}
```

```hcl
# ---- modules/s3-bucket/main.tf ----

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

```hcl
# ---- modules/s3-bucket/outputs.tf ----

output "bucket_arn" {
  description = "ARN of the created bucket"
  value       = aws_s3_bucket.this.arn
}

output "bucket_id" {
  description = "ID (name) of the created bucket"
  value       = aws_s3_bucket.this.id
}
```

```bash
# Don't apply yet -- this module is just a template
# It does nothing on its own until someone calls it
```

---

### Step 2 -- Call the Module from Root

```hcl
# ---- main.tf (root) ----

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

# Call our module -- like calling a function
module "app_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "abhik-day4-app-bucket"
  environment = "dev"
}
```

```bash
terraform init     # downloads/registers the local module
terraform plan     # you'll see: module.app_bucket.aws_s3_bucket.this
terraform apply
```

---

### Step 3 -- Expose Module Outputs

Module outputs are NOT automatically shown. Re-export them from root.

```hcl
# ---- outputs.tf (root) ----

output "app_bucket_arn" {
  value = module.app_bucket.bucket_arn
}

output "app_bucket_id" {
  value = module.app_bucket.bucket_id
}
```

```bash
terraform apply
terraform output              # now you see the module's outputs
terraform output app_bucket_arn
```

---

### Step 4 -- Reuse the Module (Multiple Calls)

The power of modules: call the same one multiple times with different inputs.

```hcl
# ---- main.tf (add these below the first module call) ----

module "logs_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "abhik-day4-logs-bucket"
  environment = "prod"
}

module "backups_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "abhik-day4-backups-bucket"
  environment = "prod"
}
```

```hcl
# ---- outputs.tf (add these) ----

output "logs_bucket_arn" {
  value = module.logs_bucket.bucket_arn
}

output "backups_bucket_arn" {
  value = module.backups_bucket.bucket_arn
}
```

```bash
terraform plan
# You'll see 3 buckets -- all from the same module, different inputs
terraform apply
terraform state list
# module.app_bucket.aws_s3_bucket.this
# module.logs_bucket.aws_s3_bucket.this
# module.backups_bucket.aws_s3_bucket.this
```

---

### Step 5 -- Module with for_each

Instead of repeating `module {}` blocks, use `for_each` to loop.

```hcl
# ---- main.tf (replace the 3 individual module calls with this) ----

variable "buckets" {
  default = {
    app     = { name = "abhik-day4-app-bucket",     env = "dev" }
    logs    = { name = "abhik-day4-logs-bucket",     env = "prod" }
    backups = { name = "abhik-day4-backups-bucket",  env = "prod" }
  }
}

module "buckets" {
  source   = "./modules/s3-bucket"
  for_each = var.buckets

  bucket_name = each.value.name
  environment = each.value.env
}
```

```hcl
# ---- outputs.tf (replace with this) ----

output "all_bucket_arns" {
  value = { for k, v in module.buckets : k => v.bucket_arn }
}
```

```bash
terraform plan
# module.buckets["app"], module.buckets["logs"], module.buckets["backups"]
terraform apply
terraform output all_bucket_arns
```

---

### Step 6 -- Use a Registry Module

Try a community module from the Terraform Registry.

```hcl
# ---- main.tf (add this) ----

module "s3_bucket_registry" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "abhik-day4-registry-demo"

  versioning = {
    enabled = true
  }

  tags = {
    Environment = "dev"
    Day         = "4"
  }
}
```

```hcl
# ---- outputs.tf (add this) ----

output "registry_bucket_arn" {
  value = module.s3_bucket_registry.s3_bucket_arn
}
```

```bash
terraform init       # downloads the registry module
terraform plan       # see all the resources the module creates
terraform apply
```

---

### Step 7 -- Pass Outputs Between Modules

One module's output becomes another module's input.

```hcl
# ---- modules/s3-bucket/variables.tf (add this) ----

variable "logging_bucket_id" {
  description = "Bucket to send access logs to (optional)"
  type        = string
  default     = ""
}
```

```hcl
# ---- main.tf (root, chain the modules) ----

module "logs_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "abhik-day4-logs-bucket"
  environment = "prod"
}

module "app_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "abhik-day4-app-bucket"
  environment = "dev"

  logging_bucket_id = module.logs_bucket.bucket_id   # output -> input
}
```

```bash
terraform plan
# Terraform auto-detects: logs_bucket must be created before app_bucket
# because app_bucket depends on logs_bucket's output
```

---

### Step 8 -- Clean Up

```bash
terraform destroy    # deletes all resources from all modules
terraform state list # should be empty
```

---

## Done?

After completing all 8 steps you understand:
- A module is just a folder of `.tf` files with inputs (variables) and outputs
- How to create, call, and reuse local modules
- How to use `for_each` with modules for DRY infrastructure
- How to use registry modules (and why to pin versions)
- How outputs chain between modules (output of one = input of another)
- How module resources appear in state (`module.<name>.<resource>`)
