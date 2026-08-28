# Day 5: Terraform State

## What is Terraform State?

- Terraform uses a **state file** (`terraform.tfstate`) to map real-world resources to your configuration
- It acts as a **source of truth** for Terraform to know what it manages
- State is stored in JSON format
- By default, state is stored locally in the working directory

## Why State Matters

- **Performance**: Terraform uses state to determine what changes need to be applied without querying every resource from the cloud provider
- **Dependency tracking**: State records resource dependencies so Terraform knows the correct order to create/destroy resources
- **Mapping**: Links resource addresses in config (e.g., `aws_instance.web`) to actual cloud resource IDs
- Without state, Terraform would have no way to know which resources it manages

## The `terraform.tfstate` File

- JSON file created after the first `terraform apply`
- Contains all resource attributes, metadata, and dependency info
- **Never edit this file manually** -- use CLI commands instead
- A backup is saved as `terraform.tfstate.backup` before each change

### Example state entry

```json
{
  "resources": [
    {
      "type": "aws_instance",
      "name": "web",
      "instances": [
        {
          "attributes": {
            "id": "i-0abc123def456",
            "ami": "ami-0c55b159cbfafe1f0",
            "instance_type": "t2.micro"
          }
        }
      ]
    }
  ]
}
```

## State Commands

### `terraform state list`

Lists all resources tracked in state.

```bash
terraform state list
# aws_instance.web
# aws_s3_bucket.data
```

### `terraform state show <resource>`

Shows detailed attributes of a specific resource.

```bash
terraform state show aws_instance.web
# id          = "i-0abc123def456"
# ami         = "ami-0c55b159cbfafe1f0"
# instance_type = "t2.micro"
# ...
```

### `terraform state mv <source> <destination>`

Renames a resource in state without destroying and recreating it.

```bash
# Rename a resource (after renaming in config)
terraform state mv aws_instance.web aws_instance.app_server
```

Use cases:
- Refactoring resource names in your config
- Moving a resource into or out of a module

### `terraform state rm <resource>`

Removes a resource from state without destroying the actual infrastructure.

```bash
terraform state rm aws_instance.web
```

Use cases:
- When you want Terraform to stop managing a resource
- When you need to import a resource under a different address

## Sensitive Data in State

- State files can contain **secrets** (database passwords, API keys, etc.)
- The state file is stored as **plain text JSON** -- treat it as sensitive
- Never commit `terraform.tfstate` to version control
- Use `.gitignore` to exclude it:

```gitignore
*.tfstate
*.tfstate.backup
```

## State Locking

- Prevents concurrent operations from corrupting state
- Local state uses the filesystem lock
- Remote backends (covered in Day 6) use mechanisms like DynamoDB for locking
- If a lock gets stuck, you can force-unlock:

```bash
terraform force-unlock <LOCK_ID>
```

## Key Takeaways

1. State is how Terraform tracks what it manages in the real world
2. Never edit `terraform.tfstate` manually -- use `terraform state` commands
3. State contains sensitive data -- keep it secure and out of version control
4. State locking prevents concurrent modifications
5. Understanding state is critical before moving to remote state (Day 6)

---

## Follow-Up: Learn by Doing (Step-by-Step)

### Step 1 -- Create Resources and Observe State

Set up a simple config to create resources and inspect the state file.

```
day5/
  aws/
    main.tf
    outputs.tf
```

```hcl
# ---- aws/main.tf ----

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

resource "aws_s3_bucket" "app" {
  bucket = "abhik-day5-app-bucket"

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Day         = "5"
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "abhik-day5-logs-bucket"

  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
    Day         = "5"
  }
}
```

```bash
terraform init
terraform apply

# After apply, a terraform.tfstate file appears in the directory
# Open it -- it's just JSON with all your resource attributes
```

---

### Step 2 -- `terraform state list`

```bash
terraform state list
# aws_s3_bucket.app
# aws_s3_bucket.logs
```

This shows every resource Terraform is tracking. Compare this to what you see in the AWS console.

---

### Step 3 -- `terraform state show`

```bash
terraform state show aws_s3_bucket.app
# Shows all attributes: arn, bucket, id, tags, region, etc.

terraform state show aws_s3_bucket.logs
```

This is how Terraform "sees" each resource -- all the attributes it has cached.

---

### Step 4 -- `terraform state mv` (Rename a Resource)

Rename a resource in your config, then move it in state so Terraform doesn't destroy and recreate it.

```hcl
# ---- Change in main.tf: rename "app" to "application" ----
# resource "aws_s3_bucket" "application" {   <-- was "app"
```

```bash
# Move in state FIRST (before running plan)
terraform state mv aws_s3_bucket.app aws_s3_bucket.application

terraform plan
# Should show: No changes. Infrastructure is up-to-date.
# Without the state mv, Terraform would destroy "app" and create "application"
```

---

### Step 5 -- `terraform state rm` (Stop Managing a Resource)

Remove a resource from state without destroying it in AWS.

```bash
terraform state rm aws_s3_bucket.logs

terraform state list
# Only aws_s3_bucket.application remains

terraform plan
# Terraform no longer knows about logs bucket
# The bucket still exists in AWS -- Terraform just forgot about it
```

---

### Step 6 -- `terraform import` (Re-adopt a Resource)

Bring the logs bucket back under Terraform management.

```bash
# Add the resource block back in main.tf (if removed), then:
terraform import aws_s3_bucket.logs abhik-day5-logs-bucket

terraform state list
# aws_s3_bucket.application
# aws_s3_bucket.logs       <-- back!

terraform plan
# May show tag differences if import didn't capture everything -- apply to sync
```

---

### Step 7 -- Inspect the State File

```bash
# View the raw state (JSON)
terraform show -json | python -m json.tool

# Or just open terraform.tfstate in your editor
# Look for:
#   - "resources" array
#   - Each resource has "type", "name", "instances"
#   - Each instance has "attributes" with all the cloud values
```

---

### Step 8 -- Clean Up

```bash
terraform destroy    # deletes all resources
terraform state list # should be empty
```

---

## Done?

After completing all 8 steps you understand:
- State is created automatically after `terraform apply`
- `terraform state list` shows what Terraform manages
- `terraform state show` reveals all cached attributes of a resource
- `terraform state mv` lets you rename resources without recreating them
- `terraform state rm` makes Terraform "forget" a resource (doesn't destroy it)
- `terraform import` brings existing infrastructure under Terraform control
- The state file is plain JSON -- treat it as sensitive, never commit it
