# Day 3: Resources & Data Sources (80/20)

## Resource — creates/manages real infrastructure

A resource is anything Terraform creates: an EC2 instance, S3 bucket, VPC, etc.

```hcl
# Syntax: resource "<provider>_<type>" "<local_name>" { ... }
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "my-web-server"
  }
}
```

### Key parts
| Part | Meaning |
|------|---------|
| `aws_instance` | Resource type (provider_type) |
| `web` | Local name (used to reference it: `aws_instance.web.id`) |
| `ami`, `instance_type` | Arguments (what you configure) |
| `id`, `arn`, `public_ip` | Attributes (what Terraform gives back after creation) |

### Resource behavior
| Command | What happens |
|---------|-------------|
| `terraform plan` | Shows what WILL be created/changed/destroyed |
| `terraform apply` | Actually creates it |
| `terraform destroy` | Deletes it |
| Change an argument | `apply` updates it (in-place or destroy+recreate) |
| Remove the block | `apply` destroys the resource |

---

## Data Source — reads EXISTING infrastructure (doesn't create anything)

Use `data` to fetch info about things that already exist (created manually, by another team, etc.).

```hcl
# Syntax: data "<provider>_<type>" "<local_name>" { ... }
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

Then use it:
```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.latest_amazon_linux.id   # reference with data. prefix
  instance_type = "t2.micro"
}
```

### Resource vs Data Source

| | Resource | Data Source |
|--|----------|------------|
| Keyword | `resource` | `data` |
| Does it create? | Yes | No — read-only |
| Reference | `aws_instance.web.id` | `data.aws_ami.latest.id` |
| In state? | Yes (tracks lifecycle) | Yes (caches the read) |
| Use when | You want Terraform to OWN it | It already exists, you just need info |

---

## Resource Dependencies

Terraform auto-detects dependencies from references:

```hcl
# Terraform knows: create VPC first, then subnet (implicit dependency)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "web" {
  vpc_id     = aws_vpc.main.id     # <-- this reference = implicit dependency
  cidr_block = "10.0.1.0/24"
}
```

When there's no reference but order matters, use `depends_on`:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  depends_on = [aws_s3_bucket.config]    # explicit: create bucket before instance
}
```

---

## Meta-Arguments (work on ANY resource)

| Meta-Argument | What it does |
|---------------|-------------|
| `depends_on` | Force ordering between resources |
| `count` | Create multiple copies: `count = 3` |
| `for_each` | Create one per item in a map/set |
| `provider` | Use a specific provider alias |
| `lifecycle` | Control create/update/destroy behavior |

### count
```hcl
resource "aws_instance" "web" {
  count         = 3                             # creates 3 instances
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  tags = {
    Name = "web-${count.index}"                 # web-0, web-1, web-2
  }
}
# Reference: aws_instance.web[0].id, aws_instance.web[1].id
```

### for_each
```hcl
resource "aws_s3_bucket" "buckets" {
  for_each = toset(["logs", "data", "backups"]) # one bucket per item
  bucket   = "myapp-${each.value}-bucket"
}
# Reference: aws_s3_bucket.buckets["logs"].arn
```

### lifecycle
```hcl
resource "aws_instance" "web" {
  # ...

  lifecycle {
    create_before_destroy = true    # new one up before old one dies (zero downtime)
    prevent_destroy       = true    # terraform destroy will ERROR (safety net)
    ignore_changes        = [tags]  # don't update if tags change outside Terraform
  }
}
```

---

## Key Commands
```bash
terraform plan               # preview changes
terraform apply              # create resources
terraform state list         # list all resources in state
terraform state show <name>  # show details of one resource
terraform destroy            # delete everything
```

## Common Gotchas
- Changing some arguments forces **destroy + recreate** (e.g., changing AMI on EC2).
  `terraform plan` shows this as `-/+` — read it carefully before apply.
- `count` uses index — removing an item from the middle reshuffles all indexes.
  Prefer `for_each` for stable identities.
- Data sources run on EVERY plan/apply — they're not cached between runs.
- `prevent_destroy = true` protects against `terraform destroy`, NOT against
  deleting the resource block from code (that removes it from state entirely).

---

## Follow-Up: Learn by Doing (Step-by-Step)

### Step 1 — Create a Basic Resource

```hcl
# ---- main.tf ----

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

# Your first resource — a simple S3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "abhik-day3-learn-bucket"

  tags = {
    Name        = "Day3 Demo"
    Environment = "dev"
  }
}
```

```bash
terraform init
terraform plan      # see what will be created
terraform apply     # type "yes" to create it
```

---

### Step 2 — Reference Resource Attributes

```hcl
# ---- outputs.tf ----

# After apply, Terraform exposes attributes you can reference
output "bucket_arn" {
  value = aws_s3_bucket.my_bucket.arn
}

output "bucket_region" {
  value = aws_s3_bucket.my_bucket.region
}
```

```bash
terraform apply
terraform output    # see the ARN and region
```

---

### Step 3 — Use a Data Source

Fetch an existing AWS resource you didn't create with Terraform.

```hcl
# ---- main.tf (add this) ----

# Fetch info about the current AWS account — doesn't create anything
data "aws_caller_identity" "current" {}

# Fetch the default VPC — it already exists in your account
data "aws_vpc" "default" {
  default = true
}
```

```hcl
# ---- outputs.tf (add these) ----

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "default_vpc_id" {
  value = data.aws_vpc.default.id
}
```

```bash
terraform plan     # no resources to create — data sources just read
terraform apply
terraform output   # see your account ID and default VPC ID
```

---

### Step 4 — Resource Dependencies

Create two resources where one depends on the other.

```hcl
# ---- main.tf (add this) ----

# Second bucket that depends on the first one existing
resource "aws_s3_bucket" "logs" {
  bucket = "abhik-day3-logs-bucket"

  tags = {
    Name = "Logs Bucket"
  }
}

# This object goes INSIDE the first bucket
# Terraform auto-detects: bucket must exist first (implicit dependency)
resource "aws_s3_object" "readme" {
  bucket  = aws_s3_bucket.my_bucket.id    # <-- implicit dependency
  key     = "readme.txt"
  content = "This bucket was created by Terraform on Day 3"
}
```

```bash
terraform plan
# Notice the order: bucket created first, then the object inside it
terraform apply
```

---

### Step 5 — count (Multiple Resources)

```hcl
# ---- main.tf (add this) ----

# Create 3 S3 buckets using count
resource "aws_s3_bucket" "multi" {
  count  = 3
  bucket = "abhik-day3-multi-${count.index}"    # multi-0, multi-1, multi-2

  tags = {
    Name = "Bucket ${count.index}"
  }
}
```

```hcl
# ---- outputs.tf (add this) ----

# Output all bucket ARNs as a list
output "multi_bucket_arns" {
  value = aws_s3_bucket.multi[*].arn
}
```

```bash
terraform plan    # see 3 buckets being created
terraform apply
```

---

### Step 6 — for_each (Better Than count)

```hcl
# ---- main.tf (add this) ----

# for_each with a set — one bucket per environment
resource "aws_s3_bucket" "env_buckets" {
  for_each = toset(["dev", "staging", "prod"])
  bucket   = "abhik-day3-${each.value}-data"

  tags = {
    Environment = each.value
  }
}
```

```hcl
# ---- outputs.tf (add this) ----

# each.key = the map key or set value
output "env_bucket_ids" {
  value = { for k, v in aws_s3_bucket.env_buckets : k => v.id }
}
```

```bash
terraform plan    # see 3 named buckets (dev, staging, prod)
terraform apply
```

---

### Step 7 — lifecycle Rules

```hcl
# ---- main.tf (update my_bucket) ----

resource "aws_s3_bucket" "my_bucket" {
  bucket = "abhik-day3-learn-bucket"

  tags = {
    Name        = "Day3 Demo"
    Environment = "dev"
  }

  lifecycle {
    prevent_destroy = true    # safety: can't accidentally destroy this
    ignore_changes  = [tags]  # Terraform won't care if tags change outside
  }
}
```

```bash
terraform plan
# Try: terraform destroy — it will ERROR because of prevent_destroy
# Remove prevent_destroy when you actually want to clean up
```

---

### Step 8 — Clean Up

```bash
# Remove prevent_destroy from the lifecycle block first, then:
terraform destroy    # deletes everything Terraform created
terraform state list # should be empty
```

---

## Done?

After completing all 8 steps you understand:
- `resource` creates things, `data` reads existing things
- How to reference attributes: `resource_type.name.attribute`
- Implicit vs explicit (`depends_on`) dependencies
- `count` vs `for_each` — and why `for_each` is usually better
- `lifecycle` rules for safety and control
- How to inspect state with `terraform state list/show`
