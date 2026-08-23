# 30-Day Terraform Masterclass Roadmap

## Week 1: Foundations

| Day | Topic | What You Learn |
|-----|-------|---------------|
| 1 | **Providers** | What providers are, declaring, configuring, version constraints, `terraform init` |
| 2 | **Variables & Outputs** | Variable types, tfvars, validation, sensitive vars, outputs, precedence order |
| 3 | **Resources & Data Sources** | Resource lifecycle, data sources, dependencies, count, for_each, lifecycle rules |
| 4 | **Modules** | Local modules, inputs/outputs, reuse, for_each with modules, registry modules |
| 5 | **State** | What state is, `terraform.tfstate`, state commands (list/show/mv/rm), why state matters |
| 6 | **Remote State** | S3 + DynamoDB backend, state locking, `terraform_remote_state` data source, migrating local to remote |
| 7 | **Week 1 Project** | Build a complete S3 static website using modules, remote state, and variables |

## Week 2: Core Workflows

| Day | Topic | What You Learn |
|-----|-------|---------------|
| 8 | **Expressions & Functions** | Interpolation, conditionals (`condition ? true : false`), built-in functions (lookup, merge, join, flatten) |
| 9 | **Locals** | Local values, when to use locals vs variables, simplifying complex expressions |
| 10 | **Dynamic Blocks** | `dynamic` blocks for repeated nested blocks, `for_each` inside resources |
| 11 | **Provisioners** | local-exec, remote-exec, file provisioner, why provisioners are a last resort, user_data alternative |
| 12 | **Import & State Manipulation** | `terraform import`, `import` block (v1.5+), `terraform state mv/rm`, adopting existing infrastructure |
| 13 | **Workspaces** | Default workspace, creating/switching workspaces, workspace-based environments, when NOT to use them |
| 14 | **Week 2 Project** | Multi-environment VPC setup (dev/staging/prod) using workspaces and dynamic blocks |

## Week 3: AWS Infrastructure Patterns

| Day | Topic | What You Learn |
|-----|-------|---------------|
| 15 | **VPC & Networking** | VPC, subnets (public/private), internet gateway, NAT gateway, route tables, security groups |
| 16 | **EC2 & Key Pairs** | Instances, AMI lookup with data sources, key pairs, user_data scripts, elastic IPs |
| 17 | **IAM** | Users, groups, roles, policies, policy documents with `aws_iam_policy_document`, instance profiles |
| 18 | **RDS & Secrets** | RDS instances, subnet groups, parameter groups, storing secrets with SSM/Secrets Manager |
| 19 | **Load Balancing** | ALB, target groups, listeners, health checks, HTTPS with ACM certificates |
| 20 | **S3 Advanced** | Bucket policies, versioning, lifecycle rules, replication, static website hosting, CloudFront |
| 21 | **Week 3 Project** | Deploy a 2-tier web app: ALB + EC2 (public) + RDS (private) with proper IAM and networking |

## Week 4: Production & Advanced

| Day | Topic | What You Learn |
|-----|-------|---------------|
| 22 | **CI/CD for Terraform** | GitHub Actions / GitLab CI pipeline, plan on PR, apply on merge, OIDC auth (no static keys) |
| 23 | **Testing** | `terraform validate`, `terraform plan` as test, `terraform test` (v1.6+), writing `.tftest.hcl` files |
| 24 | **Drift Detection & Compliance** | Detecting config drift, `terraform plan -refresh-only`, Sentinel / OPA policy-as-code intro |
| 25 | **Advanced Modules** | Module composition, nested modules, optional variables, variable validation, module versioning with Git tags |
| 26 | **Terraform Cloud / HCP** | Remote execution, private registry, team access, cost estimation, run triggers |
| 27 | **Multi-Region & Multi-Account** | Provider aliases, `for_each` on providers, assume_role for cross-account, multi-region patterns |
| 28 | **ECS / EKS** | Containerized workloads: ECS Fargate task definitions + services, or EKS cluster basics |
| 29 | **Monitoring & Observability** | CloudWatch alarms, SNS topics, log groups, dashboards -- all in Terraform |
| 30 | **Capstone Project** | Production-grade infrastructure: multi-env, CI/CD, remote state, modules, monitoring, ALB + ECS/EKS |

---

## Progress Tracker

- [x] Day 1 -- Providers
- [x] Day 2 -- Variables & Outputs
- [x] Day 3 -- Resources & Data Sources
- [x] Day 4 -- Modules
- [ ] Day 5 -- State
- [ ] Day 6 -- Remote State
- [ ] Day 7 -- Week 1 Project
- [ ] Day 8 -- Expressions & Functions
- [ ] Day 9 -- Locals
- [ ] Day 10 -- Dynamic Blocks
- [ ] Day 11 -- Provisioners
- [ ] Day 12 -- Import & State Manipulation
- [ ] Day 13 -- Workspaces
- [ ] Day 14 -- Week 2 Project
- [ ] Day 15 -- VPC & Networking
- [ ] Day 16 -- EC2 & Key Pairs
- [ ] Day 17 -- IAM
- [ ] Day 18 -- RDS & Secrets
- [ ] Day 19 -- Load Balancing
- [ ] Day 20 -- S3 Advanced
- [ ] Day 21 -- Week 3 Project
- [ ] Day 22 -- CI/CD for Terraform
- [ ] Day 23 -- Testing
- [ ] Day 24 -- Drift Detection & Compliance
- [ ] Day 25 -- Advanced Modules
- [ ] Day 26 -- Terraform Cloud / HCP
- [ ] Day 27 -- Multi-Region & Multi-Account
- [ ] Day 28 -- ECS / EKS
- [ ] Day 29 -- Monitoring & Observability
- [ ] Day 30 -- Capstone Project

---

## Tips

- **Each day = ~1-2 hours**: concept (30 min) + hands-on (60 min)
- **Always destroy after practice**: avoid surprise AWS bills
- **Use free-tier eligible resources**: t2.micro, S3, basic RDS
- **Commit your code daily**: track your progress in Git
- **Week-end projects**: tie everything together -- skip theory, just build
