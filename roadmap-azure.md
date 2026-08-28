# 30-Day Terraform with Azure Masterclass Roadmap

## Week 1: Foundations

| Day | Topic | What You Learn |
|-----|-------|---------------|
| 1 | **Providers** | AzureRM provider, declaring, configuring, version constraints, `terraform init`, Azure CLI auth |
| 2 | **Variables & Outputs** | Variable types, tfvars, validation, sensitive vars, outputs, precedence order |
| 3 | **Resources & Data Sources** | Resource lifecycle, data sources, dependencies, count, for_each, lifecycle rules |
| 4 | **Modules** | Local modules, inputs/outputs, reuse, for_each with modules, registry modules |
| 5 | **State** | What state is, `terraform.tfstate`, state commands (list/show/mv/rm), why state matters |
| 6 | **Remote State** | Azure Storage Account backend, state locking with blob lease, `terraform_remote_state` data source, migrating local to remote |
| 7 | **Week 1 Project** | Build a complete Azure Storage static website using modules, remote state, and variables |

## Week 2: Core Workflows

| Day | Topic | What You Learn |
|-----|-------|---------------|
| 8 | **Expressions & Functions** | Interpolation, conditionals (`condition ? true : false`), built-in functions (lookup, merge, join, flatten) |
| 9 | **Locals** | Local values, when to use locals vs variables, simplifying complex expressions |
| 10 | **Dynamic Blocks** | `dynamic` blocks for repeated nested blocks, `for_each` inside resources |
| 11 | **Provisioners** | local-exec, remote-exec, file provisioner, why provisioners are a last resort, custom_data alternative |
| 12 | **Import & State Manipulation** | `terraform import`, `import` block (v1.5+), `terraform state mv/rm`, adopting existing Azure infrastructure |
| 13 | **Workspaces** | Default workspace, creating/switching workspaces, workspace-based environments, when NOT to use them |
| 14 | **Week 2 Project** | Multi-environment VNet setup (dev/staging/prod) using workspaces and dynamic blocks |

## Week 3: Azure Infrastructure Patterns

| Day | Topic | What You Learn |
|-----|-------|---------------|
| 15 | **VNet & Networking** | Virtual Network, subnets (public/private), Network Security Groups, route tables, NAT Gateway, Azure Bastion |
| 16 | **Virtual Machines & SSH Keys** | Linux/Windows VMs, image lookup with data sources, SSH keys, custom_data scripts, public IPs |
| 17 | **Identity & Access (RBAC)** | Azure AD (Entra ID), service principals, managed identities, role assignments, custom role definitions |
| 18 | **Azure SQL & Secrets** | Azure SQL Database, server configuration, firewall rules, storing secrets with Key Vault |
| 19 | **Load Balancing** | Azure Application Gateway, backend pools, health probes, HTTPS with Key Vault certificates, Azure Load Balancer |
| 20 | **Storage Advanced** | Blob containers, lifecycle management, versioning, replication (GRS/ZRS), static website hosting, Azure CDN |
| 21 | **Week 3 Project** | Deploy a 2-tier web app: App Gateway + VMs (public subnet) + Azure SQL (private subnet) with proper RBAC and networking |

## Week 4: Production & Advanced

| Day | Topic | What You Learn |
|-----|-------|---------------|
| 22 | **CI/CD for Terraform** | Azure DevOps Pipelines / GitHub Actions, plan on PR, apply on merge, workload identity federation (no static secrets) |
| 23 | **Testing** | `terraform validate`, `terraform plan` as test, `terraform test` (v1.6+), writing `.tftest.hcl` files |
| 24 | **Drift Detection & Compliance** | Detecting config drift, `terraform plan -refresh-only`, Azure Policy, Sentinel / OPA policy-as-code intro |
| 25 | **Advanced Modules** | Module composition, nested modules, optional variables, variable validation, module versioning with Git tags |
| 26 | **Terraform Cloud / HCP** | Remote execution, private registry, team access, cost estimation, run triggers |
| 27 | **Multi-Region & Multi-Subscription** | Provider aliases, `for_each` on providers, multi-subscription patterns, Azure Lighthouse for cross-tenant |
| 28 | **ACI / AKS** | Containerized workloads: Azure Container Instances for simple tasks, AKS cluster with node pools and RBAC |
| 29 | **Monitoring & Observability** | Azure Monitor alerts, Action Groups, Log Analytics workspace, Application Insights, dashboards -- all in Terraform |
| 30 | **Capstone Project** | Production-grade infrastructure: multi-env, CI/CD, remote state, modules, monitoring, App Gateway + ACI/AKS |

---

## Progress Tracker

- [ ] Day 1 -- Providers (AzureRM)
- [ ] Day 2 -- Variables & Outputs
- [ ] Day 3 -- Resources & Data Sources
- [ ] Day 4 -- Modules
- [ ] Day 5 -- State
- [ ] Day 6 -- Remote State (Azure Storage)
- [ ] Day 7 -- Week 1 Project
- [ ] Day 8 -- Expressions & Functions
- [ ] Day 9 -- Locals
- [ ] Day 10 -- Dynamic Blocks
- [ ] Day 11 -- Provisioners
- [ ] Day 12 -- Import & State Manipulation
- [ ] Day 13 -- Workspaces
- [ ] Day 14 -- Week 2 Project
- [ ] Day 15 -- VNet & Networking
- [ ] Day 16 -- Virtual Machines & SSH Keys
- [ ] Day 17 -- Identity & Access (RBAC)
- [ ] Day 18 -- Azure SQL & Secrets
- [ ] Day 19 -- Load Balancing
- [ ] Day 20 -- Storage Advanced
- [ ] Day 21 -- Week 3 Project
- [ ] Day 22 -- CI/CD for Terraform
- [ ] Day 23 -- Testing
- [ ] Day 24 -- Drift Detection & Compliance
- [ ] Day 25 -- Advanced Modules
- [ ] Day 26 -- Terraform Cloud / HCP
- [ ] Day 27 -- Multi-Region & Multi-Subscription
- [ ] Day 28 -- ACI / AKS
- [ ] Day 29 -- Monitoring & Observability
- [ ] Day 30 -- Capstone Project

---

## Tips

- **Each day = ~1-2 hours**: concept (30 min) + hands-on (60 min)
- **Always destroy after practice**: avoid surprise Azure bills
- **Use free-tier eligible resources**: B1s VMs, Azure SQL Basic, Storage LRS
- **Set up spending alerts**: use Azure Cost Management budgets from day one
- **Commit your code daily**: track your progress in Git
- **Week-end projects**: tie everything together -- skip theory, just build

---

## Key AWS to Azure Mapping

| AWS Concept | Azure Equivalent |
|-------------|-----------------|
| VPC | Virtual Network (VNet) |
| EC2 | Virtual Machines |
| S3 | Azure Blob Storage |
| RDS | Azure SQL Database |
| ALB | Application Gateway / Load Balancer |
| IAM Roles | Managed Identities + RBAC |
| CloudWatch | Azure Monitor + Log Analytics |
| ECS/EKS | ACI / AKS |
| Secrets Manager | Azure Key Vault |
| SNS | Action Groups |
| Route 53 | Azure DNS |
| CloudFront | Azure CDN / Front Door |
| S3 + DynamoDB backend | Azure Storage Account backend |
