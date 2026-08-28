# Day 1: Terraform Providers (80/20)

## What is a Provider?
A plugin that lets Terraform talk to a cloud/service API (AWS, Azure, GCP, Docker, etc.).
No provider = Terraform can't manage anything.

## The 3 Things That Matter

### 1. Declare it
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"   # who/what from registry
      version = "~> 5.92"         # version constraint
    }
  }
}
```

### 2. Configure it
```hcl
provider "aws" {
  region = "us-east-1"
}
```

### 3. Download it
```bash
terraform init    # downloads provider into .terraform/
```

## Version Constraints (must-know)

| Operator | Example | Meaning |
|----------|---------|---------|
| `~>` | `"~> 5.92"` | >= 5.92, < 6.0 (safest, use this by default) |
| `>=` | `">= 1.2"` | 1.2 or anything newer |
| `=` | `"= 5.92.0"` | Exact version only |

## Key Commands
```bash
terraform init              # download providers
terraform init -upgrade     # update providers within constraints
terraform providers         # list providers in use
```

## Common Gotchas
- Forgot `terraform init` after adding a provider? Nothing works.
- `.terraform/` is local, never commit it (add to .gitignore).
- `.terraform.lock.hcl` IS committed -- it locks exact versions for the team.
- Provider credentials (AWS keys, etc.) go in env vars, never in .tf files.
