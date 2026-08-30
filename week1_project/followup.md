# Week 1 Project -- S3 Static Website

**Goal:** build a complete S3 static website using everything from Days 1-6:
providers, variables, resources & data sources, modules, state, and remote state.

No new theory. Just build it.

## What You're Building

```
                +---------------------------+
                |  S3 bucket (website)      |
   browser ---> |  index.html / error.html  |
                |  public read via policy   |
                +---------------------------+
                            ^
                            | managed by
                            |
                +---------------------------+
                |  root config              |
                |  module "static_site"     |
                |  backend "s3" (remote)    |
                +---------------------------+
                            |
                            v
                +---------------------------+
                |  S3 state bucket          |
                |  DynamoDB lock table      |
                |  (Day 6 bootstrap)        |
                +---------------------------+
```

## Concepts You Must Use

| Day | Concept | Where it shows up |
|-----|---------|-------------------|
| 1 | Providers | `required_providers` + version constraint, `provider "aws"` |
| 2 | Variables & Outputs | `variables.tf`, `terraform.tfvars`, validation, outputs |
| 3 | Resources & Data Sources | `aws_s3_bucket*`, `data "aws_caller_identity"`, `for_each` on files |
| 4 | Modules | `modules/static-website/` called from root |
| 5 | State | `terraform state list` / `show` to inspect what you built |
| 6 | Remote State | `backend "s3"` + DynamoDB locking |

---

## Target Layout

```
week1_project/
  aws/
    main.tf              # provider + backend + module call
    variables.tf         # project_name, environment, region, tags
    outputs.tf           # website endpoint, bucket name
    terraform.tfvars     # your actual values
    site/
      index.html
      error.html
    modules/
      static-website/
        main.tf
        variables.tf
        outputs.tf
```

---

### Step 0 -- Reuse the Day 6 Backend

You already created the state bucket and lock table on Day 6:

- bucket: `abhik-day6-terraform-state`
- table:  `abhik-day6-terraform-locks`

Confirm they still exist before starting:

```bash
aws s3 ls s3://abhik-day6-terraform-state/
aws dynamodb describe-table --table-name abhik-day6-terraform-locks --query "Table.TableStatus"
```

If you destroyed them at the end of Day 6, re-run the `day6-RemoteState/aws/backend-setup`
config first. Use a **new state key** for this project so it doesn't collide with Day 6:

```
key = "week1/static-site/terraform.tfstate"
```

---

### Step 1 -- Write the Module First

Build `modules/static-website/` so the root config stays thin. The module owns:

1. `aws_s3_bucket` -- the website bucket
2. `aws_s3_bucket_website_configuration` -- index + error document
3. `aws_s3_bucket_public_access_block` -- must **allow** public policy for a public site
4. `aws_s3_bucket_ownership_controls` -- `BucketOwnerPreferred`
5. `aws_s3_bucket_policy` -- public `s3:GetObject`
6. `aws_s3_object` -- upload the HTML files with `for_each`

Module inputs to expose (`variables.tf`):

| Variable | Type | Notes |
|----------|------|-------|
| `bucket_name` | `string` | must be globally unique |
| `index_document` | `string` | default `"index.html"` |
| `error_document` | `string` | default `"error.html"` |
| `source_dir` | `string` | local path holding the HTML files |
| `tags` | `map(string)` | default `{}` |

Module outputs: `bucket_id`, `bucket_arn`, `website_endpoint`.

Hints:

- `fileset(var.source_dir, "**/*.html")` gives you the file list for `for_each`
- set `content_type = "text/html"` on the objects or the browser will download them
- `aws_s3_bucket_policy` must depend on the public access block, otherwise the apply
  races and fails with `AccessDenied` -- use `depends_on`

---

### Step 2 -- Wire the Root Config

`main.tf` holds three things and nothing else:

```hcl
terraform {
  required_providers { ... }   # Day 1
  backend "s3" { ... }         # Day 6, new key
}

provider "aws" { region = var.aws_region }

module "static_site" {
  source = "./modules/static-website"
  # ...
}
```

Root variables to define:

- `project_name` (string)
- `environment` (string, with `validation` restricting it to dev/staging/prod -- Day 2)
- `aws_region` (string, default `"ap-south-1"`)
- `common_tags` (map(string))

Compose the bucket name from the variables rather than hardcoding it, e.g.
`"${var.project_name}-${var.environment}-site"`.

---

### Step 3 -- Add a Data Source

Prove Day 3 in the root config -- look something up instead of hardcoding it:

```hcl
data "aws_caller_identity" "current" {}
```

Then use `data.aws_caller_identity.current.account_id` in a tag or in the bucket name
suffix to guarantee global uniqueness.

---

### Step 4 -- Write the HTML

`site/index.html` and `site/error.html`. Keep them trivial -- one heading each is enough.
The point is the plumbing, not the page.

---

### Step 5 -- Init, Plan, Apply

```bash
cd week1_project/aws
terraform init      # should say: Successfully configured the backend "s3"!
terraform validate
terraform fmt -recursive
terraform plan
terraform apply
```

Watch for these in the plan:

- module resources are prefixed `module.static_site.`
- one `aws_s3_object` per HTML file, keyed by filename

---

### Step 6 -- Verify It Actually Works

```bash
terraform output website_endpoint
curl http://<endpoint>
curl http://<endpoint>/does-not-exist   # should return your error.html
```

Open the endpoint in a browser. If you get `403`, the bucket policy or the public
access block is wrong -- that's the usual failure.

---

### Step 7 -- Inspect the State (Day 5 + Day 6)

```bash
terraform state list
terraform state show module.static_site.aws_s3_bucket.this

# no local state file -- it's in S3
ls terraform.tfstate

aws s3 ls s3://abhik-day6-terraform-state/week1/static-site/
```

---

### Step 8 -- Prove Locking Works

Two terminals, same directory, run `terraform plan` in both at once. The second should
fail with `Error acquiring the state lock`.

---

### Step 9 -- Clean Up

```bash
terraform destroy
```

`aws_s3_object` resources are destroyed by Terraform, so the bucket empties itself and
the delete succeeds. If you added files manually outside Terraform, the destroy fails
with `BucketNotEmpty` -- empty it first:

```bash
aws s3 rm s3://<bucket> --recursive
```

Leave the Day 6 backend bucket and lock table in place -- Week 2 will reuse them.

---

## Done Checklist

- [ ] Module created under `modules/static-website/` with typed inputs and outputs
- [ ] Root config calls the module -- no `aws_s3_bucket` resources at root level
- [ ] Variables used for every name, region, and tag (nothing hardcoded twice)
- [ ] At least one variable has a `validation` block
- [ ] At least one data source used
- [ ] State lives in S3, not on disk
- [ ] Locking verified with two concurrent runs
- [ ] Website endpoint returns `index.html` in a browser
- [ ] `terraform destroy` runs clean
- [ ] Committed to Git

---

## Stretch Goals (optional)

1. Serve the site over HTTPS by putting CloudFront in front of the bucket
   (this is Day 20 territory -- skip if it stalls you)
2. Add a second environment by changing only `terraform.tfvars` and the backend `key`
3. Add a `terraform_remote_state` data source in a throwaway config that reads this
   project's `website_endpoint` output
