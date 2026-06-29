# Enterprise Cost Estimation & Trade-off Analysis

This document provides approximate monthly running cost calculations for the networking infrastructure across Development, Staging, and Production environments.

---

## Monthly Cost Projections (Mumbai Region - ap-south-1)

AWS pricing defaults:
- **NAT Gateway**: $0.045/hour (~$32.40/month) + $0.045/GB processed.
- **Interface VPC Endpoint**: $0.01/hour per Availability Zone (~$7.20/month per AZ) + $0.01/GB processed.
- **Gateway VPC Endpoint (S3)**: Free ($0.00).
- **VPC Flow Logs Ingestion**: $0.50/GB.
- **CloudWatch Logs Storage**: $0.03/GB per month.

### 1. Development Environment
*Cost-optimized configuration.*
- **NAT Gateways**: 1 Shared NAT Gateway -> **$32.40**
- **Interface Endpoints**: 9 Endpoints deployed in 1 AZ (for testing ECR/SSM/Logs) -> 9 * $7.20 = **$64.80**
- **Gateway Endpoints**: S3 Endpoint -> **$0.00**
- **VPC Flow Logs**: Ingestion & Storage (~5 GB traffic logged, 30-day retention) -> **~$2.65**
- **Baseline Total**: **~$99.85 / month** (plus data transfer/processing).

### 2. Staging Environment
*Semi-HA configuration.*
- **NAT Gateways**: 1 Shared NAT Gateway -> **$32.40**
- **Interface Endpoints**: 9 Endpoints deployed in 2 AZs -> 9 * 2 * $7.20 = **$129.60**
- **Gateway Endpoints**: S3 Endpoint -> **$0.00**
- **VPC Flow Logs**: Ingestion & Storage (~15 GB traffic logged, 90-day retention) -> **~$8.50**
- **Baseline Total**: **~$170.50 / month** (plus data transfer/processing).

### 3. Production Environment
*Fully Highly Available & Compliant configuration.*
- **NAT Gateways**: 3 NAT Gateways (1 per AZ) -> 3 * $32.40 = **$97.20**
- **Interface Endpoints**: 9 Endpoints deployed in 3 AZs -> 9 * 3 * $7.20 = **$194.40**
- **Gateway Endpoints**: S3 Endpoint -> **$0.00**
- **VPC Flow Logs**: Ingestion & Storage (~100 GB traffic logged, 365-day retention) -> **~$59.00**
- **Baseline Total**: **~$350.60 / month** (plus data transfer/processing).

---

## Architectural Cost Trade-offs

### 1. Single vs. Multi NAT Gateway
- **Trade-off**: A single NAT Gateway is a Single Point of Failure (SPOF). If AZ-A experiences a power failure, traffic inside private subnets in AZ-B and AZ-C will lose outbound access to ECR/APIs.
- **Decision**: Dev and Stage use `single_nat_gateway = true` to save ~$64/month. Prod uses `single_nat_gateway = false` to satisfy high-availability SLA.

### 2. Interface Endpoints vs. NAT Gateway Routing
- **Trade-off**: Putting interface endpoints for ECR and CloudWatch logs inside the VPC costs $194.40/month in Prod. We could route ECR pulls over the NAT Gateway for free, but it increases NAT data processing fees ($0.045/GB vs. $0.010/GB) and sends traffic over public IP ranges.
- **Decision**: In Prod, PrivateLink is chosen because it meets HIPAA requirements for network isolation and is more cost-efficient for heavy data flows (e.g. daily large container image pulls and log forwarding).

### 3. S3 Gateway vs. Interface Endpoint
- **Trade-off**: AWS offers S3 both as a Gateway Endpoint and an Interface Endpoint. Interface endpoints cost hourly fees; Gateway endpoints are free and configured directly in route tables.
- **Decision**: S3 Gateway is used for all environments, saving $21.60/month in Prod while enabling maximum data throughput without limits or data processing fees.

### 4. CloudWatch Logs Retention
- **Trade-off**: CloudWatch log storage accumulates cost over time. Storing massive flow logs indefinitely gets expensive.
- **Decision**: Retention is tiered (30 days for dev, 90 for stage, 365 for prod) to meet HIPAA audit history requirements in Prod while minimizing Dev/Stage storage bloat.
