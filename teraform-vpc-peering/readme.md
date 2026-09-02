

Terraform vpc peering guide · MD
# Terraform VPC Peering — End-to-End Learning Project
 
A single hands-on project that teaches: providers, variables, modules, module reuse, inter-module wiring, outputs, state, and AWS VPC peering.
 
**What you build:** two non-overlapping VPCs (`app-vpc`, `database-vpc`), a peering connection between them, and routes on both sides so traffic can flow.
 
**Prereqs:** Terraform ≥ 1.5, AWS CLI configured (`aws sts get-caller-identity` works), an AWS account. Everything here fits in free tier — VPCs, subnets, route tables, and peering inside one region cost nothing.
 
---
 
## 0. Mental model (read this first)
 
Peering is a **private road between two buildings**.
 
```
Building A                          Building B
app-vpc                             database-vpc
10.0.0.0/16                         10.1.0.0/16
     |                                    |
     +----------- Private Road -----------+
                       |
                  VPC Peering
```
 
The road alone does nothing. Each building must also be told *"to reach the other building, use this road."* That instruction is the **route**. Three pieces, always:
 
```
VPC A  +  VPC B  +  (peering connection + routes on BOTH sides)
```
 
Miss the routes and `terraform apply` succeeds while nothing can talk. This is the #1 beginner failure.
 
**Non-negotiable rule:** the two CIDRs must not overlap. `10.0.0.0/16` and `10.1.0.0/16` are fine. `10.0.0.0/16` twice is rejected by AWS.
 
**Peering is not transitive.** A↔B and B↔C does not give you A↔C. You'd need A↔C explicitly.
 
---
 
## 1. Folder structure
 
```
terraform-vpc-peering/
├── main.tf              # calls the modules, wires them together
├── variables.tf         # input knobs for the root module
├── outputs.tf           # what gets printed after apply
├── versions.tf          # terraform + provider pinning
├── terraform.tfvars     # actual values for the variables
│
└── modules/
    ├── vpc/             # reusable: makes ONE vpc + subnet + route table
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── vpc-peering/     # reusable: connects TWO existing vpcs
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```
 
Create it:
 
```bash
mkdir -p terraform-vpc-peering/modules/{vpc,vpc-peering}
cd terraform-vpc-peering
touch main.tf variables.tf outputs.tf versions.tf terraform.tfvars
touch modules/vpc/{main,variables,outputs}.tf
touch modules/vpc-peering/{main,variables,outputs}.tf
```
 
**Module design principle at work here:** each module has exactly one responsibility. `vpc` knows how to build a VPC and nothing about peering. `vpc-peering` knows how to connect two VPCs and nothing about how they were created. That separation is why the `vpc` module can be called twice with different values.
 
```
Root module
   ├── module "app_vpc"       → vpc module  → VPC + subnet + route table
   ├── module "database_vpc"  → vpc module  → VPC + subnet + route table
   └── module "vpc_peering"   → peering module → peering + 2 routes
```
 
---
 
## 2. `versions.tf`
 
```hcl
terraform {
  required_version = ">= 1.5.0"
 
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
 
provider "aws" {
  region = var.aws_region
}
```
 
| Line | Meaning |
|---|---|
| `required_version = ">= 1.5.0"` | Refuse to run on older Terraform. |
| `source = "hashicorp/aws"` | Download the official AWS provider from the registry. |
| `version = "~> 6.0"` | Allow 6.x, block 7.0. Pessimistic constraint — safe minor upgrades, no surprise breaking changes. |
| `provider "aws"` | Configures *how* to talk to AWS. Credentials come from your environment/AWS CLI, never hardcode them here. |
 
**Learning note — the provider block goes in the root only.** Child modules inherit the root's provider. Putting a `provider` block inside a module makes that module non-reusable and breaks `terraform destroy` in ugly ways. Modules declare `required_providers`, not `provider`.
 
---
 
## 3. `variables.tf` (root)
 
```hcl
variable "aws_region" {
  description = "AWS region where the VPCs will be created"
  type        = string
  default     = "us-east-1"
}
 
variable "app_vpc_cidr" {
  description = "CIDR block for the application VPC"
  type        = string
  default     = "10.0.0.0/16"
}
 
variable "database_vpc_cidr" {
  description = "CIDR block for the database VPC"
  type        = string
  default     = "10.1.0.0/16"
}
 
variable "app_subnet_cidr" {
  description = "Subnet CIDR for the application VPC"
  type        = string
  default     = "10.0.1.0/24"
}
 
variable "database_subnet_cidr" {
  description = "Subnet CIDR for the database VPC"
  type        = string
  default     = "10.1.1.0/24"
}
```
 
**CIDR sanity check:**
 
```
app-vpc       10.0.0.0/16   → usable range 10.0.0.0   – 10.0.255.255
  app subnet  10.0.1.0/24   → 10.0.1.0 – 10.0.1.255   (inside the VPC ✓)
 
database-vpc  10.1.0.0/16   → usable range 10.1.0.0   – 10.1.255.255
  db subnet   10.1.1.0/24   → 10.1.1.0 – 10.1.1.255   (inside the VPC ✓)
```
 
Two rules you just used:
1. A subnet CIDR must be **inside** its VPC CIDR.
2. The two VPC CIDRs must **not overlap** with each other.
---
 
## 4. `main.tf` (root) — the wiring
 
```hcl
module "app_vpc" {
  source = "./modules/vpc"
 
  vpc_name    = "app-vpc"
  vpc_cidr    = var.app_vpc_cidr
  subnet_cidr = var.app_subnet_cidr
}
 
module "database_vpc" {
  source = "./modules/vpc"
 
  vpc_name    = "database-vpc"
  vpc_cidr    = var.database_vpc_cidr
  subnet_cidr = var.database_subnet_cidr
}
 
module "vpc_peering" {
  source = "./modules/vpc-peering"
 
  requester_vpc_id = module.app_vpc.vpc_id
  accepter_vpc_id  = module.database_vpc.vpc_id
 
  requester_route_table_id = module.app_vpc.route_table_id
  accepter_route_table_id  = module.database_vpc.route_table_id
 
  requester_vpc_cidr = module.app_vpc.vpc_cidr
  accepter_vpc_cidr  = module.database_vpc.vpc_cidr
 
  peering_name = "app-to-database-peering"
}
```
 
This file is the single most important thing to understand.
 
`module.app_vpc.vpc_id` reads: *"the output named `vpc_id`, from the module block named `app_vpc`."* Same `source`, called twice, different names, different values → two independent sets of resources.
 
**Learning note — implicit dependency graph.** You never wrote `depends_on`. Because `module.vpc_peering` references `module.app_vpc.vpc_id`, Terraform *derives* that the VPC must exist first. It builds a DAG from these references and creates the two VPCs in parallel, then the peering. Reach for explicit `depends_on` only when a real dependency exists that isn't visible as a reference (rare).
 
---
 
## 5. `outputs.tf` (root)
 
```hcl
output "app_vpc_id" {
  description = "ID of the application VPC"
  value       = module.app_vpc.vpc_id
}
 
output "database_vpc_id" {
  description = "ID of the database VPC"
  value       = module.database_vpc.vpc_id
}
 
output "app_subnet_id" {
  description = "ID of the application subnet"
  value       = module.app_vpc.subnet_id
}
 
output "database_subnet_id" {
  description = "ID of the database subnet"
  value       = module.database_vpc.subnet_id
}
 
output "vpc_peering_connection_id" {
  description = "ID of the VPC peering connection"
  value       = module.vpc_peering.peering_connection_id
}
```
 
After apply:
 
```
app_vpc_id                = "vpc-0123456789abcdef0"
database_vpc_id           = "vpc-0987654321fedcba0"
app_subnet_id             = "subnet-0123456789abcdef0"
database_subnet_id        = "subnet-0987654321fedcba0"
vpc_peering_connection_id = "pcx-0123456789abcdef0"
```
 
**Learning note — outputs bubble up.** A module output is invisible outside the module until a parent re-exports it. Root outputs are how you get values out for humans, for CI, or for another config via `terraform_remote_state`.
 
---
 
## 6. `terraform.tfvars`
 
```hcl
aws_region = "us-east-1"
 
app_vpc_cidr      = "10.0.0.0/16"
database_vpc_cidr = "10.1.0.0/16"
 
app_subnet_cidr      = "10.0.1.0/24"
database_subnet_cidr = "10.1.1.0/24"
```
 
For Mumbai: `aws_region = "ap-south-1"`.
 
**Learning note — variable precedence**, lowest to highest:
 
```
default in variables.tf
  → terraform.tfvars  (auto-loaded)
    → *.auto.tfvars   (auto-loaded)
      → TF_VAR_ env vars
        → -var-file=... on the CLI
          → -var 'key=value' on the CLI   ← wins
```
 
`terraform.tfvars` is loaded automatically. A file named `prod.tfvars` is not — you'd pass `-var-file=prod.tfvars`.
 
---
 
## 7. `modules/vpc/variables.tf`
 
```hcl
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}
 
variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}
 
variable "subnet_cidr" {
  description = "CIDR block of the subnet"
  type        = string
}
```
 
No `default` → these are **required**. Terraform errors at plan time if a caller forgets one. That's deliberate: a VPC module has no business guessing your CIDR.
 
The same module, two call sites:
 
| | `module "app_vpc"` | `module "database_vpc"` |
|---|---|---|
| `vpc_name` | `app-vpc` | `database-vpc` |
| `vpc_cidr` | `10.0.0.0/16` | `10.1.0.0/16` |
| `subnet_cidr` | `10.0.1.0/24` | `10.1.1.0/24` |
 
Same code. Different values. Different real resources. That is the whole point of modules.
 
---
 
## 8. `modules/vpc/main.tf`
 
```hcl
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
 
  enable_dns_support   = true
  enable_dns_hostnames = true
 
  tags = {
    Name = var.vpc_name
  }
}
 
resource "aws_subnet" "this" {
  vpc_id     = aws_vpc.this.id
  cidr_block = var.subnet_cidr
 
  tags = {
    Name = "${var.vpc_name}-subnet"
  }
}
 
resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id
 
  tags = {
    Name = "${var.vpc_name}-route-table"
  }
}
 
resource "aws_route_table_association" "this" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_route_table.this.id
}
```
 
Line by line:
 
**`aws_vpc.this`** — creates the network boundary. `enable_dns_support` + `enable_dns_hostnames` are on because peered VPCs commonly need DNS resolution; leaving them off is a classic "why can't I resolve this" afternoon.
 
**`aws_subnet.this`** — `vpc_id = aws_vpc.this.id` places it inside the VPC just created. Another implicit dependency.
 
**`aws_route_table.this`** — an empty custom route table. AWS auto-creates a *main* route table per VPC, but you want your own so the peering routes are explicit and managed by Terraform.
 
**`aws_route_table_association.this`** — without this, the subnet silently falls back to the main route table and your peering route is never consulted. Easy to forget, hard to debug.
 
Resulting shape:
 
```
VPC
├── Subnet ──────┐
└── Route Table ─┘  (associated)
```
 
**Learning note — why the label `"this"`.** When a module creates exactly one of something, naming it `this` is the community convention. You reference it as `aws_vpc.this` inside the module; from outside it's `module.app_vpc.vpc_id`. The module name already provides the meaningful namespace, so `aws_vpc.app_vpc` inside a module called `app_vpc` would just stutter.
 
---
 
## 9. `modules/vpc/outputs.tf`
 
```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}
 
output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}
 
output "subnet_id" {
  description = "ID of the subnet"
  value       = aws_subnet.this.id
}
 
output "route_table_id" {
  description = "ID of the route table"
  value       = aws_route_table.this.id
}
```
 
This is the module's **public API**. Everything else inside the module is private. The peering module needs the ID, the CIDR, and the route table ID — so those are exported, and that's exactly why they're here.
 
Note `vpc_cidr` is read back from `aws_vpc.this.cidr_block` (the real attribute) rather than echoing `var.vpc_cidr`. Prefer outputting the resource attribute: it's the value AWS actually assigned.
 
---
 
## 10. `modules/vpc-peering/variables.tf`
 
```hcl
variable "requester_vpc_id" {
  description = "ID of the VPC that starts the peering request"
  type        = string
}
 
variable "accepter_vpc_id" {
  description = "ID of the VPC that accepts the peering request"
  type        = string
}
 
variable "requester_route_table_id" {
  description = "Route table ID of the requester VPC"
  type        = string
}
 
variable "accepter_route_table_id" {
  description = "Route table ID of the accepter VPC"
  type        = string
}
 
variable "requester_vpc_cidr" {
  description = "CIDR block of the requester VPC"
  type        = string
}
 
variable "accepter_vpc_cidr" {
  description = "CIDR block of the accepter VPC"
  type        = string
}
 
variable "peering_name" {
  description = "Name of the VPC peering connection"
  type        = string
}
```
 
**Requester vs accepter:** peering is a handshake. One side requests, the other accepts. Within a single account and region you can set `auto_accept = true` and Terraform does both halves. Across accounts or regions, the accepter side needs its own provider/config and an `aws_vpc_peering_connection_accepter` resource.
 
The module asks only for IDs, CIDRs, and route table IDs — plain strings. It never asks "how were these VPCs made?" That's what makes it reusable against VPCs you didn't create.
 
---
 
## 11. `modules/vpc-peering/main.tf` (complete)
 
```hcl
resource "aws_vpc_peering_connection" "this" {
  vpc_id      = var.requester_vpc_id
  peer_vpc_id = var.accepter_vpc_id
  auto_accept = true
 
  tags = {
    Name = var.peering_name
  }
}
 
resource "aws_route" "requester_to_accepter" {
  route_table_id            = var.requester_route_table_id
  destination_cidr_block    = var.accepter_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}
 
resource "aws_route" "accepter_to_requester" {
  route_table_id            = var.accepter_route_table_id
  destination_cidr_block    = var.requester_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}
```
 
### 11.1 The connection
 
`vpc_id` = requester side, `peer_vpc_id` = accepter side. `auto_accept = true` completes the handshake because both VPCs are in the same account and region.
 
```
app-vpc  <------ pcx-xxxx ------>  database-vpc
```
 
### 11.2 Route: app → database
 
```hcl
route_table_id            = var.requester_route_table_id  # app-vpc's table
destination_cidr_block    = var.accepter_vpc_cidr         # 10.1.0.0/16
vpc_peering_connection_id = aws_vpc_peering_connection.this.id
```
 
Reads as: *"traffic destined for 10.1.0.0/16, send it over the peering connection."*
 
### 11.3 Route: database → app
 
The mirror image. **Both directions are required.** With only one route you get a request that arrives and a reply that can't get home — the connection just times out. Routing is per-direction, always.
 
```
app-vpc 10.0.0.0/16
      │
      │ dest 10.1.0.0/16 → pcx
      ▼
  VPC Peering
      ▲
      │ dest 10.0.0.0/16 → pcx
      │
database-vpc 10.1.0.0/16
```
 
---
 
## 12. `modules/vpc-peering/outputs.tf`
 
```hcl
output "peering_connection_id" {
  description = "ID of the VPC peering connection"
  value       = aws_vpc_peering_connection.this.id
}
```
 
---
 
## 13. Run it
 
```bash
cd terraform-vpc-peering
 
terraform init            # download provider, register modules, create .terraform/
terraform fmt -recursive  # canonical formatting, including modules/
terraform validate        # syntax + type checking, no AWS calls
terraform plan            # calls AWS to read state, shows the diff
terraform apply           # type: yes
```
 
What each command actually does:
 
| Command | What happens |
|---|---|
| `init` | Downloads `hashicorp/aws`, writes `.terraform.lock.hcl`, resolves `source = "./modules/..."`. **Re-run after adding a module or changing a provider version.** |
| `fmt -recursive` | Rewrites `.tf` files to canonical style. `-recursive` is what reaches into `modules/`. |
| `validate` | Offline. Catches typos, wrong types, missing required variables. Fast feedback loop. |
| `plan` | Reads real AWS state, compares to config + state file, prints `+ create` / `~ update` / `-/+ replace` / `- destroy`. **Read this every time.** |
| `apply` | Executes the plan. Writes `terraform.tfstate`. |
 
Expect roughly 9 resources: 2 VPCs, 2 subnets, 2 route tables, 2 associations, 1 peering connection, plus the 2 routes.
 
### Verify
 
```bash
terraform output
 
aws ec2 describe-vpc-peering-connections \
  --query 'VpcPeeringConnections[].{ID:VpcPeeringConnectionId,Status:Status.Code}'
```
 
Status should be `active`. Then confirm the routes landed:
 
```bash
aws ec2 describe-route-tables \
  --query 'RouteTables[].Routes[?VpcPeeringConnectionId!=`null`]'
```
 
### Tear down
 
```bash
terraform destroy
```
 
Do this when you're done. Peering costs nothing at rest, but leaving orphaned infra is a bad habit and free-tier accounts get cluttered fast.
 
---
 
## 14. What this project deliberately does NOT create
 
- EC2 instances
- Security groups (beyond the default)
- Internet Gateway / NAT Gateway
- Load balancers
- Any database
- Network ACLs
This is the **network foundation only**. If you later put an EC2 in each VPC, they still won't talk until security groups allow it:
 
```
App EC2  ──TCP 5432──▶  Database EC2
```
 
Split the responsibility clearly in your head:
 
| Layer | Question it answers |
|---|---|
| Peering + routes | *Is there a path?* |
| Security groups | *Is this specific traffic allowed?* |
| Network ACLs | *Is this traffic allowed at the subnet edge?* |
 
All three must say yes. Peering gives you only the first.
 
**Nice bonus:** a security group in one VPC can reference a security group in the peered VPC by ID — cleaner than hardcoding CIDRs.
 
---
 
## 15. Common failures and what they mean
 
| Symptom | Cause | Fix |
|---|---|---|
| `InvalidVpcPeeringConnectionId` on apply | Route created before peering was active | Usually transient; `terraform apply` again |
| Apply succeeds, hosts can't ping | Missing route on one side, or missing subnet↔route-table association | Check both `aws_route` resources exist and both associations are applied |
| `overlapping CIDR blocks` | The two VPC CIDRs intersect | Change one VPC's CIDR; requires recreating the VPC |
| `Module not installed` | Added a module block without re-initializing | `terraform init` |
| Instances still can't connect after routes are correct | Security groups | Open the specific port between the two CIDRs |
| DNS names don't resolve across the peering | DNS resolution not enabled on the peering connection | Enable `allow_remote_vpc_dns_resolution` in the peering options block |
| Plan wants to destroy things you didn't touch | Wrong workspace, or state file lost/not shared | Check `terraform workspace show`; move to remote state |
 
---
 
## 16. Extensions — do these to actually master it
 
Work through in order. Each one teaches a distinct Terraform concept.
 
1. **Add a third VPC** (`10.2.0.0/16`) and peer it to `app-vpc`.
   → Proves module reuse and proves peering is not transitive: the third VPC still can't reach `database-vpc`.
2. **Add validation** to the CIDR variables:
```hcl
   validation {
     condition     = can(cidrhost(var.vpc_cidr, 0))
     error_message = "vpc_cidr must be a valid CIDR block."
   }
```
   → Fail at plan time instead of mid-apply.
 
3. **Add a `tags` map variable** to the vpc module and merge it:
```hcl
   tags = merge(var.tags, { Name = var.vpc_name })
```
   → Teaches `merge()` and the standard tagging pattern.
 
4. **Multiple subnets with `for_each`**, keyed by availability zone.
   → Teaches `for_each`, `data "aws_availability_zones"`, and why `for_each` beats `count` for named resources.
5. **Move state to S3** with DynamoDB locking.
   → The single biggest step toward using Terraform on a team.
6. **Add `terraform workspace`** for dev/staging with different CIDRs.
   → Same code, multiple environments.
7. **Cross-region peering.** Add a second aliased provider and use `aws_vpc_peering_connection_accepter`.
   → Teaches provider aliases, the hardest concept in this list.
8. **Deliberately break it.** Delete a VPC in the AWS console, then run `terraform plan`.
   → Teaches what drift is and how state reconciles with reality.
---
 
## 17. Concept checklist
 
By the end of this project you should be able to explain, without looking:
 
- [ ] Why the provider block belongs in root and not in modules
- [ ] What `~> 6.0` allows and what it blocks
- [ ] The full variable precedence order
- [ ] How Terraform builds its dependency graph without `depends_on`
- [ ] Why a module output is required to pass a value upward
- [ ] Why the same module called twice creates two independent resource sets
- [ ] Why routes are needed on both sides of a peering connection
- [ ] What breaks if you skip `aws_route_table_association`
- [ ] The difference between "path exists" (routes) and "traffic allowed" (security groups)
- [ ] Why peering is not transitive
- [ ] What the state file is and why losing it is bad
---
 
## 18. The one-paragraph summary
 
Two modules with clean, single responsibilities: `vpc` builds a VPC with a subnet and its own route table; `vpc-peering` takes two already-existing VPCs and connects them with a peering connection plus a route in each direction. The root module calls `vpc` twice and feeds both sets of outputs into `vpc-peering`. Terraform infers the ordering from those references. The result is a private path between two isolated networks — a path, not permission. Permission is security groups, and that's the next project.
 
