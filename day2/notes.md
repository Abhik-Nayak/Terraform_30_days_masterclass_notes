# Day 2: Variables & Outputs (80/20)

## Variables — make configs reusable

### 3 ways to define a variable
```hcl
variable "region" {
  description = "AWS region"       # what it's for
  type        = string             # string, number, bool, list, map, object
  default     = "us-east-1"        # optional — no default = Terraform asks you
}
```

### 5 ways to SET a variable (priority order, highest wins)
1. Command line: `terraform apply -var="region=us-west-2"`
2. `.tfvars` file: `terraform apply -var-file="prod.tfvars"`
3. `terraform.tfvars` or `*.auto.tfvars` (auto-loaded)
4. Environment variable: `TF_VAR_region=us-west-2`
5. Default value in the variable block

### Variable types
| Type | Example |
|------|---------|
| `string` | `"us-east-1"` |
| `number` | `3` |
| `bool` | `true` |
| `list(string)` | `["us-east-1", "us-west-2"]` |
| `map(string)` | `{ dev = "t2.micro", prod = "t2.large" }` |
| `object({...})` | `{ name = string, age = number }` |

### Validation (optional but useful)
```hcl
validation {
  condition     = contains(["dev", "staging", "prod"], var.environment)
  error_message = "Must be dev, staging, or prod."
}
```

### Sensitive variables
```hcl
variable "db_password" {
  type      = string
  sensitive = true    # hides value in plan/apply output
}
```

## Outputs — expose values after apply

```hcl
output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.demo.arn
}
```

- Shown after `terraform apply`
- Queryable: `terraform output bucket_arn`
- Used to pass data between modules (Day 4+)

## File conventions
| File | Purpose |
|------|---------|
| `variables.tf` | All variable declarations |
| `outputs.tf` | All output declarations |
| `terraform.tfvars` | Default variable values (auto-loaded) |
| `prod.tfvars` | Environment-specific overrides |

## Key Commands
```bash
terraform plan                            # uses defaults + terraform.tfvars
terraform plan -var="environment=prod"    # override one var
terraform plan -var-file="prod.tfvars"    # use a specific file
terraform output                          # show all outputs
terraform output bucket_arn               # show one output
```

## Common Gotchas
- No default + no value provided = Terraform prompts interactively (breaks CI).
- `terraform.tfvars` is auto-loaded; other `.tfvars` files need `-var-file`.
- Never put secrets in `.tfvars` — use env vars or a secrets manager.
- `sensitive = true` hides output, but the value is still in state file (plain text).

---

## Follow-Up: Learn by Doing (Step-by-Step)

### Step 1 — Basic Variable

Create these two files and run `terraform init` then `terraform plan`.

```hcl
# ---- variables.tf ----

# A simple variable with a default value
# Since it has a default, Terraform won't prompt you
variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}
```

```hcl
# ---- main.tf ----

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
  required_version = ">= 1.2"
}

# var.region references the variable declared above
provider "aws" {
  region = var.region
}
```

```bash
terraform init
terraform plan
# You should see: provider region = "us-east-1" (the default)
```

---

### Step 2 — Variable Without Default

Add a variable with NO default — Terraform will force you to provide it.

```hcl
# ---- variables.tf (add this below the region variable) ----

# No default = Terraform will prompt you or throw an error
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  # notice: no default here!
}
```

```hcl
# ---- main.tf (add this below the provider block) ----

# Use var.bucket_name to reference the variable
resource "aws_s3_bucket" "demo" {
  bucket = var.bucket_name
}
```

```bash
# Try 1: no value provided — Terraform prompts you interactively
terraform plan

# Try 2: pass value via -var flag — no prompt
terraform plan -var="bucket_name=my-test-bucket-12345"
```

---

### Step 3 — tfvars File

Instead of typing `-var` every time, put values in a file.

```hcl
# ---- terraform.tfvars ----
# This file is AUTO-LOADED by Terraform (magic filename)
# No need to pass -var-file for this one

bucket_name = "my-dev-bucket-12345"
```

```bash
# Terraform picks up terraform.tfvars automatically — no prompt
terraform plan
```

Now create a second file for production overrides:

```hcl
# ---- prod.tfvars ----
# This file is NOT auto-loaded — you must pass -var-file

bucket_name = "my-prod-bucket-12345"
```

```bash
# -var-file overrides the auto-loaded terraform.tfvars
terraform plan -var-file="prod.tfvars"
# You should see bucket_name = "my-prod-bucket-12345"
```

---

### Step 4 — Variable Types (map)

Use a `map` variable to pass structured data like tags.

```hcl
# ---- variables.tf (add this) ----

# map(string) = key-value pairs where both are strings
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "terraform-30days"
  }
}
```

```hcl
# ---- main.tf (update the s3 bucket resource) ----

resource "aws_s3_bucket" "demo" {
  bucket = var.bucket_name
  tags   = var.tags          # pass the entire map as tags
}
```

```bash
terraform plan
# You should see the tags in the plan output
```

---

### Step 5 — Validation

Restrict a variable to only allowed values.

```hcl
# ---- variables.tf (add this) ----

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  # validation block = custom rule that Terraform checks BEFORE plan/apply
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

```bash
# Test with a valid value — works fine
terraform plan -var="environment=prod"

# Test with an invalid value — see the error message
terraform plan -var="environment=banana"
# Error: Environment must be dev, staging, or prod.
```

---

### Step 6 — Sensitive Variable

Hide secret values from plan/apply output.

```hcl
# ---- variables.tf (add this) ----

# sensitive = true tells Terraform to mask this in all output
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
```

```hcl
# ---- outputs.tf (create this file) ----

# Try to output a sensitive variable — Terraform will hide the value
output "password_check" {
  description = "This will be masked in output"
  value       = var.db_password
  sensitive   = true          # required when value comes from a sensitive var
}
```

```bash
terraform plan -var="db_password=SuperSecret123"
# You'll see: password_check = (sensitive value)
# The actual value is NEVER shown in terminal
```

---

### Step 7 — Outputs

Expose useful info after `terraform apply`.

```hcl
# ---- outputs.tf (add these) ----

# Outputs are shown after apply and queryable with `terraform output`
output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.demo.arn
}

output "bucket_region" {
  description = "Region where bucket lives"
  value       = var.region
}
```

```bash
# After apply, query individual outputs
terraform output
terraform output bucket_arn
terraform output -json          # machine-readable format
```

---

### Step 8 — Environment Variable

Set variable values via environment variables (useful for CI/CD).

```hcl
# ---- variables.tf (update region to remove the default) ----

variable "region" {
  description = "AWS region to deploy into"
  type        = string
  # default removed — must be provided externally now
}
```

```powershell
# PowerShell: set env var with TF_VAR_ prefix + variable name
$env:TF_VAR_region = "us-west-2"

terraform plan
# Terraform picks up region = "us-west-2" from the environment

# Clean up the env var when done
Remove-Item Env:TF_VAR_region
```

```bash
# Bash/Linux equivalent:
export TF_VAR_region="us-west-2"
terraform plan
```

---

## Done?

After completing all 8 steps you understand:
- How to declare, type, validate, and secure variables
- 5 ways to pass values (CLI, tfvars, auto-tfvars, env var, default)
- How outputs expose data for humans and other modules
- The precedence order when multiple sources set the same variable
