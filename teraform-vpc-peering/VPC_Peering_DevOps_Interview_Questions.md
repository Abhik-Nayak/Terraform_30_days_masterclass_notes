# VPC Peering --- 10 Real-Time DevOps Interview Questions

For a DevOps interview with 3--5+ years of experience, focus on
**scenario-based troubleshooting, networking, routing, security, and
architecture**, not only definitions.

------------------------------------------------------------------------

## 1. Two VPCs are peered, but EC2 in VPC-A cannot connect to EC2 in VPC-B. How do you troubleshoot?

### Strong interview answer

I would troubleshoot layer by layer:

1.  Verify the VPC peering status is `active`.
2.  Check the route table associated with the source subnet.
3.  Confirm VPC-B CIDR points to the peering connection.
4.  Check the reverse route in VPC-B.
5.  Verify Security Groups allow the required port.
6.  Check Network ACLs.
7.  Verify the EC2 instances are actually in the expected subnets.
8.  Check whether the CIDR blocks overlap.

### Key point

> A VPC peering connection alone doesn't create routing.

------------------------------------------------------------------------

## 2. What routes are required for VPC Peering?

Suppose:

``` text
VPC-A = 10.0.0.0/16
VPC-B = 10.1.0.0/16
```

You need:

``` text
VPC-A Route Table
10.1.0.0/16 → pcx-xxxx

VPC-B Route Table
10.0.0.0/16 → pcx-xxxx
```

### Interview answer

> VPC peering requires routing on both sides because routing is
> directional.

------------------------------------------------------------------------

## 3. Can VPC Peering work if the CIDR blocks overlap?

**No.**

Example:

``` text
VPC-A → 10.0.0.0/16
VPC-B → 10.0.0.0/16
```

They cannot be peered normally because the address ranges overlap.

### Interview answer

> Before creating VPC peering, I verify that the VPC CIDRs don't
> overlap. Otherwise AWS rejects the peering configuration.

------------------------------------------------------------------------

## 4. Is VPC Peering transitive?

**No.**

Imagine:

``` text
VPC-A
   │
   │ Peering
   ▼
VPC-B
   │
   │ Peering
   ▼
VPC-C
```

Can:

``` text
A → C
```

communicate automatically?

**No.**

You need:

``` text
A ←→ B
B ←→ C
A ←→ C
```

### Interview answer

> VPC Peering is non-transitive. A peering connection between A-B and
> B-C does not automatically provide connectivity between A and C.

------------------------------------------------------------------------

## 5. VPC Peering is active and routes are correct, but TCP 5432 doesn't work. What would you check?

Suppose:

``` text
App EC2
10.0.1.10
    │
    │ TCP 5432
    ▼
Database EC2
10.1.1.10
```

I'd check:

``` text
1. App Security Group
2. Database Security Group
3. Database listening on 5432
4. Network ACLs
5. OS firewall
6. Route tables
7. Database service status
```

For example, the database Security Group should allow:

``` text
Inbound
TCP
5432
Source: App VPC CIDR / appropriate Security Group
```

### Important interview distinction

> VPC Peering provides the network path. Security Groups determine
> whether the specific traffic is allowed.

------------------------------------------------------------------------

## 6. Can you connect two VPCs in different AWS accounts?

**Yes.**

Example:

``` text
AWS Account A
      │
      ▼
    VPC-A
10.0.0.0/16
      │
      │ VPC Peering
      │
      ▼
    VPC-B
10.1.0.0/16
      │
      ▼
AWS Account B
```

Typical flow:

``` text
Account A
   ↓
Create peering request
   ↓
Account B
   ↓
Accept request
   ↓
Add routes on both sides
   ↓
Configure Security Groups
```

### Interview point

For cross-account scenarios, the accepter side needs to accept the
peering request.

------------------------------------------------------------------------

## 7. Can VPC Peering connect VPCs in different AWS regions?

**Yes.**

This is called **inter-region VPC peering**.

Example:

``` text
us-east-1
VPC-A
10.0.0.0/16
       │
       │ VPC Peering
       │
       ▼
eu-west-1
VPC-B
10.1.0.0/16
```

Things I'd verify:

-   CIDRs don't overlap.
-   Peering request/acceptance is completed.
-   Route tables are configured on both sides.
-   Security Groups allow the required traffic.
-   Network ACLs allow the required traffic.
-   Terraform provider aliases are configured correctly when required.

------------------------------------------------------------------------

## 8. What happens if you create the VPC Peering connection but don't add routes?

You can have:

``` text
VPC-A
   │
   │
   ▼
PCX
   │
   ▼
VPC-B
```

with:

``` text
Peering = ACTIVE
```

but traffic still doesn't work.

Why?

Because the route table doesn't know:

``` text
10.1.0.0/16 → pcx-xxxx
```

### Interview answer

> Peering establishes the connection, but route tables determine whether
> traffic uses that connection.

------------------------------------------------------------------------

## 9. You have three VPCs: App, DB and Monitoring. How would you design connectivity?

A beginner design might be:

``` text
App VPC
   │
   ▼
DB VPC
   │
   ▼
Monitoring VPC
```

But you cannot assume:

``` text
App → DB → Monitoring
```

means:

``` text
App → Monitoring
```

automatically.

For a small number of VPCs, you could explicitly create:

``` text
App ←→ DB
App ←→ Monitoring
DB  ←→ Monitoring
```

For larger environments, I'd evaluate **AWS Transit Gateway** rather
than creating many individual peering connections.

### Interview-quality answer

> VPC Peering works well for simple point-to-point connectivity. As the
> number of VPCs grows, I would consider Transit Gateway to avoid a
> complex peering mesh.

------------------------------------------------------------------------

## 10. You manage VPC Peering using Terraform. How do you make the configuration reusable?

I'd separate responsibilities into modules:

``` text
Root Module
     │
     ├──────────────┐
     ▼              ▼
 VPC Module      VPC Module
     │              │
     ▼              ▼
 App VPC         DB VPC
     │              │
     └──────┬───────┘
            ▼
     Peering Module
            │
            ▼
       PCX + Routes
```

### VPC module

The `vpc` module creates:

``` text
VPC
Subnet
Route Table
Route Table Association
```

### VPC Peering module

The `vpc-peering` module creates:

``` text
Peering Connection
App → DB Route
DB → App Route
```

### Root module wiring

``` hcl
requester_vpc_id = module.app_vpc.vpc_id

accepter_vpc_id = module.database_vpc.vpc_id
```

### Interview answer

> I separate VPC creation from VPC peering. The VPC module is reusable,
> while the peering module accepts VPC IDs, CIDRs, and route table IDs
> as inputs. The root module wires the outputs of the VPC modules into
> the peering module.

------------------------------------------------------------------------

# ⭐ Top 5 Questions to Memorize First

  -----------------------------------------------------------------------
  Priority                Question                Main Concept
  ----------------------- ----------------------- -----------------------
  🔥🔥🔥                  Peering is active but   Troubleshooting
                          EC2 can't connect ---   
                          how do you              
                          troubleshoot?           

  🔥🔥🔥                  Why are routes required Routing
                          on both sides?          

  🔥🔥🔥                  Is VPC Peering          Architecture
                          transitive?             

  🔥🔥🔥                  Peering works but port  SG/NACL
                          5432 fails --- why?     

  🔥🔥                    What happens with       Networking
                          overlapping CIDRs?      
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 🧠 One Answer to Remember

> **VPC Peering gives me the private network path. Route tables decide
> where traffic goes, and Security Groups and Network ACLs decide
> whether that traffic is allowed. Both VPCs need appropriate routes,
> CIDRs must not overlap, and VPC Peering is non-transitive.**

This single explanation covers many common VPC Peering interview
scenarios.

------------------------------------------------------------------------

# Quick Mental Model

``` text
             VPC PEERING
                 │
                 ▼
       ┌───────────────────┐
       │   Private Path    │
       └─────────┬─────────┘
                 │
       ┌─────────▼─────────┐
       │    Route Tables   │
       │   "Where to go?"  │
       └─────────┬─────────┘
                 │
       ┌─────────▼─────────┐
       │ Security Groups   │
       │ "Is it allowed?"  │
       └─────────┬─────────┘
                 │
       ┌─────────▼─────────┐
       │    Network ACLs   │
       │ "Subnet edge?"    │
       └───────────────────┘
```

### Remember

``` text
Peering  = Path
Routes   = Direction
SG       = Permission
NACL     = Subnet-level filter
CIDR     = Must not overlap
Peering  = Non-transitive
```
