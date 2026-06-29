# Enterprise Networking Design & Routing Tables

This document outlines the detailed subnet allocations, routing rules, and Network Access Control Lists (NACLs) configured in Phase 1.

## Subnet Allocation Layout

We implement a dynamic 3-AZ network utilizing `10.0.0.0/16` as our main VPC CIDR block.

| Subnet Tier | IP CIDR Block | AZ (ap-south-1) | Route Destination | Subnet Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **Public Subnet 1** | `10.0.1.0/24` | `ap-south-1a` | Internet Gateway | Inbound ALB, Public NAT Gateway |
| **Public Subnet 2** | `10.0.2.0/24` | `ap-south-1b` | Internet Gateway | Inbound ALB |
| **Public Subnet 3** | `10.0.3.0/24` | `ap-south-1c` | Internet Gateway | Inbound ALB |
| **Private App Subnet 1** | `10.0.10.0/24` | `ap-south-1a` | NAT Gateway / VPC Endpoint | ECS Tasks / EKS Worker Nodes |
| **Private App Subnet 2** | `10.0.11.0/24` | `ap-south-1b` | NAT Gateway / VPC Endpoint | ECS Tasks / EKS Worker Nodes |
| **Private App Subnet 3** | `10.0.12.0/24` | `ap-south-1c` | NAT Gateway / VPC Endpoint | ECS Tasks / EKS Worker Nodes |
| **Private DB Subnet 1** | `10.0.20.0/24` | `ap-south-1a` | Isolated (VPC Local Only) | PostgreSQL / DocumentDB |
| **Private DB Subnet 2** | `10.0.21.0/24` | `ap-south-1b` | Isolated (VPC Local Only) | PostgreSQL / DocumentDB |
| **Private DB Subnet 3** | `10.0.22.0/24` | `ap-south-1c` | Isolated (VPC Local Only) | PostgreSQL / DocumentDB |

---

## Route Tables Configuration

### 1. Public Route Table (`rt-public`)
Assigned to all Public Subnets.
- `10.0.0.0/16` -> Local (VPC)
- `0.0.0.0/0` -> Internet Gateway (`igw-xxxx`)
- `pl-xxxxxx` (S3) -> S3 Gateway Endpoint (`vpce-xxxxxx`)

### 2. Private Application Route Tables (`rt-private-a/b/c`)
Assigned to Private Application Subnets.
- `10.0.0.0/16` -> Local (VPC)
- `pl-xxxxxx` (S3) -> S3 Gateway Endpoint (`vpce-xxxxxx`)
- **If `single_nat_gateway = true`**:
  - `0.0.0.0/0` -> Shared NAT Gateway (`nat-gw-a` in Public 1)
- **If `single_nat_gateway = false`**:
  - Subnet A: `0.0.0.0/0` -> NAT Gateway A (`nat-gw-a`)
  - Subnet B: `0.0.0.0/0` -> NAT Gateway B (`nat-gw-b`)
  - Subnet C: `0.0.0.0/0` -> NAT Gateway C (`nat-gw-c`)

### 3. Database Route Table (`rt-database`)
Assigned to Database Subnets.
- `10.0.0.0/16` -> Local (VPC)
- `pl-xxxxxx` (S3) -> S3 Gateway Endpoint (`vpce-xxxxxx`)
- **No external route (0.0.0.0/0)** is mapped. Outbound internet connection is completely restricted.

---

## Layer-4 Network ACLs (NACL) Rules

To enforce strict boundary controls, three Network Access Control Lists (NACLs) are deployed:

### Public NACL (`nacl-public`)
- **Inbound Rules**:
  - `100`: Allow TCP 80 from `0.0.0.0/0` (Inbound HTTP traffic for ALB)
  - `110`: Allow TCP 443 from `0.0.0.0/0` (Inbound HTTPS traffic for ALB)
  - `120`: Allow TCP `1024-65535` from `0.0.0.0/0` (Allow ephemeral return traffic)
- **Outbound Rules**:
  - `100`: Allow all traffic to anywhere (`0.0.0.0/0`)

### Private Application NACL (`nacl-private`)
- **Inbound Rules**:
  - `100`: Allow all traffic from the internal VPC CIDR block (`10.0.0.0/16`).
  - `110`: Allow TCP `1024-65535` from anywhere (Return traffic from NAT gateways).
- **Outbound Rules**:
  - `100`: Allow all traffic to anywhere (`0.0.0.0/0`)

### Private Database NACL (`nacl-database`)
- **Inbound Rules**:
  - `100`: Allow TCP 5432 from VPC CIDR block (`10.0.0.0/16`) (Allows Postgres access strictly from within the VPC).
- **Outbound Rules**:
  - `100`: Allow TCP `1024-65535` to VPC CIDR block (`10.0.0.0/16`) (Allows ephemeral return traffic to Application nodes).
- **No rules mapping to `0.0.0.0/0`** are allowed.
