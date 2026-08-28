# Day 4: Modules with Azure (80/20)

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
  storage-account/
    main.tf          # resources
    variables.tf     # inputs (what the caller provides)
    outputs.tf       # outputs (what the caller gets back)
```

### 2. Call the module

```hcl
module "logs_storage" {
  source = "./modules/storage-account"     # path to the module folder

  storage_account_name = "myapplogsstore"  # pass inputs as arguments
  environment          = "prod"
}
```

### 3. Use the module's outputs

```hcl
# Access with: module.<name>.<output_name>
output "logs_storage_id" {
  value = module.logs_storage.storage_account_id
}
```

---

## Module Sources

| Source | Example | Use when |
|--------|---------|----------|
| Local path | `"./modules/storage-account"` | Your own code, same repo |
| Terraform Registry | `"Azure/storage/azurerm"` | Community/official modules |
| GitHub | `"github.com/org/repo//modules/vnet"` | Team-shared modules |
| Azure Blob | `"azurerm::https://account.blob.core.windows.net/..."` | Private module storage |

After changing the `source`, always run `terraform init` (or `terraform init -upgrade`).

---

## Module Inputs & Outputs

### Inputs = variables declared inside the module

```hcl
# ---- modules/storage-account/variables.tf ----

variable "storage_account_name" {
  description = "Name of the Azure Storage Account (3-24 chars, lowercase alphanumeric only)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "centralindia"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}
```

The caller passes values like function arguments:

```hcl
module "logs_storage" {
  source               = "./modules/storage-account"
  storage_account_name = "mylogsstore"       # required (no default)
  resource_group_name  = "my-rg"             # required (no default)
  environment          = "prod"              # optional (has default)
}
```

### Outputs = what the module exposes back

```hcl
# ---- modules/storage-account/outputs.tf ----

output "storage_account_id" {
  value = azurerm_storage_account.this.id
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.this.primary_blob_endpoint
}
```

The caller accesses them with `module.<name>.<output>`:

```hcl
resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_id    = module.logs_storage.storage_account_id   # using module output
  container_access_type = "private"
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

The Terraform Registry has pre-built modules for common Azure patterns (VNet, AKS, Key Vault, etc.).

```hcl
module "vnet" {
  source  = "Azure/vnet/azurerm"
  version = "~> 4.0"

  resource_group_name = azurerm_resource_group.this.name
  vnet_location       = azurerm_resource_group.this.location
  use_for_each        = true

  vnet_name       = "my-vnet"
  address_space   = ["10.0.0.0/16"]

  subnet_names    = ["subnet-1", "subnet-2"]
  subnet_prefixes = ["10.0.1.0/24", "10.0.2.0/24"]
}
```

```bash
terraform init      # downloads the module from registry
terraform plan
```

---

## Azure-Specific: Resource Groups

Unlike AWS, Azure requires a **Resource Group** to hold resources. Modules typically accept `resource_group_name` and `location` as inputs.

```hcl
# Root module creates the resource group, child modules receive it as input
resource "azurerm_resource_group" "this" {
  name     = "day4-modules-rg"
  location = "centralindia"
}

module "app_storage" {
  source               = "./modules/storage-account"
  storage_account_name = "abhikday4appstore"
  resource_group_name  = azurerm_resource_group.this.name   # pass RG to module
  location             = azurerm_resource_group.this.location
  environment          = "dev"
}
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
- Module resources appear in state as `module.app_storage.azurerm_storage_account.this` --
  you can't `terraform destroy` just a module; destroy its resources individually
  or remove the `module {}` block and apply.
- Changing `source` requires `terraform init` again -- Terraform doesn't auto-detect.
- Module outputs are NOT automatically exposed to the terminal.
  You must re-export them in the root module's `outputs.tf`.
- Registry modules without `version` will grab latest -- fine for experiments,
  dangerous in production. Always pin with `version = "~> X.Y"`.
- Local modules are loaded from disk every time. Registry/Git modules are cached
  in `.terraform/modules/` after `init`.
- **Azure naming**: Storage Account names must be 3-24 chars, lowercase alphanumeric
  only, globally unique. This is a common source of errors.
- **Resource Groups**: always decide whether the module creates its own RG or
  receives one. Best practice: pass in the RG, don't create it inside the module.

---

## Follow-Up: Learn by Doing (Step-by-Step)

### Step 1 -- Create a Local Module

Build a reusable Azure Storage Account module.

```
day4/
  main.tf
  outputs.tf
  modules/
    storage-account/
      main.tf
      variables.tf
      outputs.tf
```

```hcl
# ---- modules/storage-account/variables.tf ----

variable "storage_account_name" {
  description = "Name of the Storage Account (3-24 chars, lowercase alphanumeric)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "centralindia"
}

variable "environment" {
  description = "Environment tag (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Storage replication type (LRS, GRS, ZRS, RAGRS)"
  type        = string
  default     = "LRS"
}
```

```hcl
# ---- modules/storage-account/main.tf ----

resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

```hcl
# ---- modules/storage-account/outputs.tf ----

output "storage_account_id" {
  description = "ID of the created storage account"
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the created storage account"
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint URL"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_access_key" {
  description = "Primary access key (sensitive)"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
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
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "your-subscription-id"   # or set via ARM_SUBSCRIPTION_ID env var
}

# Create a resource group first (modules will use this)
resource "azurerm_resource_group" "this" {
  name     = "day4-modules-rg"
  location = "centralindia"
}

# Call our module -- like calling a function
module "app_storage" {
  source               = "./modules/storage-account"
  storage_account_name = "abhikday4appstore"
  resource_group_name  = azurerm_resource_group.this.name
  location             = azurerm_resource_group.this.location
  environment          = "dev"
}
```

```bash
terraform init     # downloads/registers the local module
terraform plan     # you'll see: module.app_storage.azurerm_storage_account.this
terraform apply
```

---

### Step 3 -- Expose Module Outputs

Module outputs are NOT automatically shown. Re-export them from root.

```hcl
# ---- outputs.tf (root) ----

output "app_storage_id" {
  value = module.app_storage.storage_account_id
}

output "app_storage_name" {
  value = module.app_storage.storage_account_name
}

output "app_blob_endpoint" {
  value = module.app_storage.primary_blob_endpoint
}
```

```bash
terraform apply
terraform output                  # now you see the module's outputs
terraform output app_storage_id
```

---

### Step 4 -- Reuse the Module (Multiple Calls)

The power of modules: call the same one multiple times with different inputs.

```hcl
# ---- main.tf (add these below the first module call) ----

module "logs_storage" {
  source               = "./modules/storage-account"
  storage_account_name = "abhikday4logsstore"
  resource_group_name  = azurerm_resource_group.this.name
  location             = azurerm_resource_group.this.location
  environment          = "prod"
}

module "backups_storage" {
  source               = "./modules/storage-account"
  storage_account_name = "abhikday4backupstore"
  resource_group_name  = azurerm_resource_group.this.name
  location             = azurerm_resource_group.this.location
  environment          = "prod"
  replication_type     = "GRS"    # geo-redundant for backups
}
```

```hcl
# ---- outputs.tf (add these) ----

output "logs_storage_id" {
  value = module.logs_storage.storage_account_id
}

output "backups_storage_id" {
  value = module.backups_storage.storage_account_id
}
```

```bash
terraform plan
# You'll see 3 storage accounts -- all from the same module, different inputs
terraform apply
terraform state list
# module.app_storage.azurerm_storage_account.this
# module.logs_storage.azurerm_storage_account.this
# module.backups_storage.azurerm_storage_account.this
```

---

### Step 5 -- Module with for_each

Instead of repeating `module {}` blocks, use `for_each` to loop.

```hcl
# ---- main.tf (replace the 3 individual module calls with this) ----

variable "storage_accounts" {
  default = {
    app     = { name = "abhikday4appstore",    env = "dev",  replication = "LRS" }
    logs    = { name = "abhikday4logsstore",   env = "prod", replication = "LRS" }
    backups = { name = "abhikday4backupstore", env = "prod", replication = "GRS" }
  }
}

module "storage" {
  source   = "./modules/storage-account"
  for_each = var.storage_accounts

  storage_account_name = each.value.name
  resource_group_name  = azurerm_resource_group.this.name
  location             = azurerm_resource_group.this.location
  environment          = each.value.env
  replication_type     = each.value.replication
}
```

```hcl
# ---- outputs.tf (replace with this) ----

output "all_storage_ids" {
  value = { for k, v in module.storage : k => v.storage_account_id }
}

output "all_blob_endpoints" {
  value = { for k, v in module.storage : k => v.primary_blob_endpoint }
}
```

```bash
terraform plan
# module.storage["app"], module.storage["logs"], module.storage["backups"]
terraform apply
terraform output all_storage_ids
```

---

### Step 6 -- Use a Registry Module

Try a community module from the Terraform Registry.

```hcl
# ---- main.tf (add this) ----

module "vnet_registry" {
  source  = "Azure/vnet/azurerm"
  version = "~> 4.0"

  resource_group_name = azurerm_resource_group.this.name
  vnet_location       = azurerm_resource_group.this.location
  use_for_each        = true

  vnet_name     = "day4-demo-vnet"
  address_space = ["10.0.0.0/16"]

  subnet_names    = ["app-subnet", "db-subnet"]
  subnet_prefixes = ["10.0.1.0/24", "10.0.2.0/24"]

  tags = {
    Environment = "dev"
    Day         = "4"
  }
}
```

```hcl
# ---- outputs.tf (add this) ----

output "vnet_id" {
  value = module.vnet_registry.vnet_id
}

output "subnet_ids" {
  value = module.vnet_registry.vnet_subnets
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
# ---- modules/storage-account/variables.tf (add this) ----

variable "network_rules_subnet_ids" {
  description = "Subnet IDs allowed to access this storage account (optional)"
  type        = list(string)
  default     = []
}
```

```hcl
# ---- modules/storage-account/main.tf (add network rules) ----

resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type

  dynamic "network_rules" {
    for_each = length(var.network_rules_subnet_ids) > 0 ? [1] : []
    content {
      default_action             = "Deny"
      virtual_network_subnet_ids = var.network_rules_subnet_ids
    }
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

```hcl
# ---- main.tf (root, chain the modules) ----

module "vnet_registry" {
  source  = "Azure/vnet/azurerm"
  version = "~> 4.0"

  resource_group_name = azurerm_resource_group.this.name
  vnet_location       = azurerm_resource_group.this.location
  use_for_each        = true

  vnet_name       = "day4-demo-vnet"
  address_space   = ["10.0.0.0/16"]
  subnet_names    = ["app-subnet"]
  subnet_prefixes = ["10.0.1.0/24"]

  subnet_service_endpoints = {
    "app-subnet" = ["Microsoft.Storage"]    # required for storage network rules
  }
}

module "app_storage" {
  source               = "./modules/storage-account"
  storage_account_name = "abhikday4appstore"
  resource_group_name  = azurerm_resource_group.this.name
  location             = azurerm_resource_group.this.location
  environment          = "dev"

  network_rules_subnet_ids = module.vnet_registry.vnet_subnets   # output -> input
}
```

```bash
terraform plan
# Terraform auto-detects: vnet must be created before storage
# because app_storage depends on vnet's subnet output
```

---

### Step 8 -- Clean Up

```bash
terraform destroy    # deletes all resources from all modules
terraform state list # should be empty
```

---

## AWS vs Azure Module Comparison

| Concept | AWS (Day 4 Notes) | Azure (This File) |
|---------|-------------------|-------------------|
| Module resource | `aws_s3_bucket` | `azurerm_storage_account` |
| Provider | `hashicorp/aws` | `hashicorp/azurerm` |
| Naming constraint | Bucket name globally unique | Storage name 3-24 chars, globally unique, lowercase alphanumeric only |
| No equivalent in AWS | -- | Resource Group (required container for all resources) |
| Registry module | `terraform-aws-modules/s3-bucket/aws` | `Azure/vnet/azurerm` |
| Cross-module linking | S3 logging bucket ID | VNet subnet IDs for network rules |
| Sensitive output | -- | `primary_access_key` (marked `sensitive = true`) |

---

## Done?

After completing all 8 steps you understand:
- A module is just a folder of `.tf` files with inputs (variables) and outputs
- How to create, call, and reuse local modules with Azure resources
- How Resource Groups fit into module design (pass in, don't create inside)
- How to use `for_each` with modules for DRY infrastructure
- How to use Azure registry modules (and why to pin versions)
- How outputs chain between modules (VNet subnet IDs -> Storage network rules)
- How module resources appear in state (`module.<name>.<resource>`)
- Azure-specific naming constraints and validation rules
