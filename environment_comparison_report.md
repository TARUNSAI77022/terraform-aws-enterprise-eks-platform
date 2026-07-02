# Terraform Environment Comparison Audit Report

This report provides a side-by-side comparative analysis of the **dev**, **stage**, and **prod** environments for the **AWS Enterprise EKS Platform** based strictly on the configurations defined in the Terraform workspace.

---

## 1. Environment Overview

| Feature | DEV (`env/dev`) | STAGE (`env/stage`) | PROD (`env/prod`) |
| :--- | :--- | :--- | :--- |
| **Region** | `ap-south-1` | `ap-south-1` | `ap-south-1` |
| **Project Name** | `cloud-foundation` | `cloud-foundation` | `cloud-foundation` |
| **Environment Name** | `dev` | `stage` | `prod` |
| **Terraform Workspace** | Directory-isolated state | Directory-isolated state | Directory-isolated state |
| **Total Terraform Resources**| **105** | **105** | **113** |
| **Est. Billable TF Resources**| **24** (1 EKS, 3 KMS, 8 ECR, 9 Endpoints, 1 NAT, 2 Node Groups) | **24** (1 EKS, 3 KMS, 8 ECR, 9 Endpoints, 1 NAT, 2 Node Groups) | **26** (1 EKS, 3 KMS, 8 ECR, 9 Endpoints, 3 NAT, 2 Node Groups) |
| **Est. Active AWS Billing Units**| **30** (24 above + 4 EC2 nodes + 4 EBS volumes) | **32** (24 above + 5 EC2 nodes + 5 EBS volumes) | **34** (26 above + 5 EC2 nodes + 5 EBS volumes) |
| **Est. Free TF Resources** | **81** | **81** | **87** |

---

## 2. Networking

| Resource / Parameter | DEV | STAGE | PROD |
| :--- | :--- | :--- | :--- |
| **VPC CIDR** | `10.0.0.0/16` | `10.0.0.0/16` | `10.0.0.0/16` |
| **Public Subnets** | 3 (`10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24`) | 3 (`10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24`) | 3 (`10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24`) |
| **Private App Subnets** | 3 (`10.0.10.0/24`, `10.0.11.0/24`, `10.0.12.0/24`) | 3 (`10.0.10.0/24`, `10.0.11.0/24`, `10.0.12.0/24`) | 3 (`10.0.10.0/24`, `10.0.11.0/24`, `10.0.12.0/24`) |
| **Private Database Subnets** | 3 (`10.0.20.0/24`, `10.0.21.0/24`, `10.0.22.0/24`) | 3 (`10.0.20.0/24`, `10.0.21.0/24`, `10.0.22.0/24`) | 3 (`10.0.20.0/24`, `10.0.21.0/24`, `10.0.22.0/24`) |
| **Availability Zones** | 3 (`ap-south-1a`, `ap-south-1b`, `ap-south-1c`) | 3 (`ap-south-1a`, `ap-south-1b`, `ap-south-1c`) | 3 (`ap-south-1a`, `ap-south-1b`, `ap-south-1c`) |
| **Internet Gateway** | 1 (`cloud-foundation-dev-igw`) | 1 (`cloud-foundation-stage-igw`) | 1 (`cloud-foundation-prod-igw`) |
| **NAT Gateway Count** | 1 (Shared in `ap-south-1a`) | 1 (Shared in `ap-south-1a`) | 3 (1 per AZ for high availability) |
| **Elastic IP Count** | 1 | 1 | 3 |
| **Route Tables** | 3 (Public, Shared Private, DB) | 3 (Public, Shared Private, DB) | 5 (Public, 3 Private, DB) |
| **Network ACLs** | 3 (Public, Private, Database) | 3 (Public, Private, Database) | 3 (Public, Private, Database) |
| **Security Groups** | 6 (ALB, App Node, SSM, DB, EKS, VPCE) | 6 (ALB, App Node, SSM, DB, EKS, VPCE) | 6 (ALB, App Node, SSM, DB, EKS, VPCE) |
| **Flow Logs** | 1 (VPC Flow Logs Enabled) | 1 (VPC Flow Logs Enabled) | 1 (VPC Flow Logs Enabled) |
| **CloudWatch Log Groups** | 1 (`/aws/vpc-flow-logs/cloud-foundation-dev`) | 1 (`/aws/vpc-flow-logs/cloud-foundation-stage`) | 1 (`/aws/vpc-flow-logs/cloud-foundation-prod`) |
| **Interface Endpoints** | 9 (ecr.api, ecr.dkr, logs, monitoring, sts, secrets, ssm, ssmmessages, ec2messages) | 9 (ecr.api, ecr.dkr, logs, monitoring, sts, secrets, ssm, ssmmessages, ec2messages) | 9 (ecr.api, ecr.dkr, logs, monitoring, sts, secrets, ssm, ssmmessages, ec2messages) |
| **Gateway Endpoints** | 1 (S3 Gateway Endpoint) | 1 (S3 Gateway Endpoint) | 1 (S3 Gateway Endpoint) |

---

## 3. Security

| Parameter | DEV | STAGE | PROD |
| :--- | :--- | :--- | :--- |
| **KMS Keys** | 3 (EKS Secrets, CW Logs, ECR Key) | 3 (EKS Secrets, CW Logs, ECR Key) | 3 (EKS Secrets, CW Logs, ECR Key) |
| **Key Rotation** | Enabled (`enable_key_rotation = true`) | Enabled (`enable_key_rotation = true`) | Enabled (`enable_key_rotation = true`) |
| **IAM Roles** | 6 (FlowLogs, Cluster, Node, EBS-CSI, ALB-Ctrl, Autoscaler) | 6 (FlowLogs, Cluster, Node, EBS-CSI, ALB-Ctrl, Autoscaler) | 6 (FlowLogs, Cluster, Node, EBS-CSI, ALB-Ctrl, Autoscaler) |
| **IAM Policies** | 2 Custom (ALB-Ctrl, Autoscaler) + AWS Managed policies attached | 2 Custom (ALB-Ctrl, Autoscaler) + AWS Managed policies attached | 2 Custom (ALB-Ctrl, Autoscaler) + AWS Managed policies attached |
| **IAM Instance Profiles** | N/A (EKS Node Group automatically provisions profile under the hood) | N/A (EKS Node Group automatically provisions profile under the hood) | N/A (EKS Node Group automatically provisions profile under the hood) |
| **OIDC Provider** | 1 (`cloud-foundation-dev-eks-oidc-provider`) | 1 (`cloud-foundation-stage-eks-oidc-provider`) | 1 (`cloud-foundation-prod-eks-oidc-provider`) |
| **IRSA** | Active (EBS CSI, AWS LB Controller, Cluster Autoscaler) | Active (EBS CSI, AWS LB Controller, Cluster Autoscaler) | Active (EBS CSI, AWS LB Controller, Cluster Autoscaler) |
| **Access Entries** | 0 (defaults to `{}`, empty map) | 0 (defaults to `{}`, empty map) | 0 (defaults to `{}`, empty map) |
| **Encryption** | KMS envelope secrets, KMS log group, KMS ECR repos, gp3 encrypted disks | KMS envelope secrets, KMS log group, KMS ECR repos, gp3 encrypted disks | KMS envelope secrets, KMS log group, KMS ECR repos, gp3 encrypted disks |
| **Secrets** | None declared in Terraform (External Secrets Scaffold is empty) | None declared in Terraform (External Secrets Scaffold is empty) | None declared in Terraform (External Secrets Scaffold is empty) |

---

## 4. EKS

| Parameter | DEV | STAGE | PROD |
| :--- | :--- | :--- | :--- |
| **Cluster Name** | `cloud-foundation-dev-eks` | `cloud-foundation-stage-eks` | `cloud-foundation-prod-eks` |
| **Kubernetes Version** | `1.30` | `1.30` | `1.30` |
| **Cluster Endpoint** | Dynamic AWS output URL | Dynamic AWS output URL | Dynamic AWS output URL |
| **Public Access** | Disabled (`endpoint_public_access = false`)| Disabled (`endpoint_public_access = false`)| Disabled (`endpoint_public_access = false`)|
| **Private Access** | Enabled (`endpoint_private_access = true`)| Enabled (`endpoint_private_access = true`)| Enabled (`endpoint_private_access = true`)|
| **Logging** | Enabled (api, audit, authenticator, controllerManager, scheduler) | Enabled (api, audit, authenticator, controllerManager, scheduler) | Enabled (api, audit, authenticator, controllerManager, scheduler) |
| **KMS Encryption** | Yes (Secrets resource envelope) | Yes (Secrets resource envelope) | Yes (Secrets resource envelope) |
| **Cluster Role** | `cloud-foundation-dev-eks-cluster-role` | `cloud-foundation-stage-eks-eks-cluster-role` | `cloud-foundation-prod-eks-eks-cluster-role` |
| **OIDC Enabled** | Yes | Yes | Yes |

---

## 5. Node Groups

| Parameter | DEV | STAGE | PROD |
| :--- | :--- | :--- | :--- |
| **Node Group Names** | `system`, `applications` | `system`, `applications` | `system`, `applications` |
| **Instance Types** | `system`: `t3.medium` <br>`applications`: `t3.medium` | `system`: `t3.large` <br>`applications`: `t3.large` | `system`: `m6i.large` <br>`applications`: `m6i.large` |
| **Capacity Type** | `system`: `ON_DEMAND`<br>`applications`: `SPOT` | `system`: `ON_DEMAND`<br>`applications`: `SPOT` | `system`: `ON_DEMAND`<br>`applications`: `ON_DEMAND` |
| **Desired Size** | `system`: 2, `applications`: 2 | `system`: 2, `applications`: 3 | `system`: 2, `applications`: 3 |
| **Minimum Size** | `system`: 1, `applications`: 1 | `system`: 2, `applications`: 2 | `system`: 2, `applications`: 3 |
| **Maximum Size** | `system`: 3, `applications`: 5 | `system`: 4, `applications`: 6 | `system`: 4, `applications`: 10 |
| **Disk Size** | 50 GB | 50 GB | 50 GB |
| **gp3** | Yes | Yes | Yes |
| **Encrypted Volumes** | Yes (EKS KMS Key) | Yes (EKS KMS Key) | Yes (EKS KMS Key) |
| **Launch Templates** | 2 (`node-system-`, `node-applications-`) | 2 (`node-system-`, `node-applications-`) | 2 (`node-system-`, `node-applications-`) |
| **IMDSv2** | Required (`http_tokens = "required"`, hop limit: 2) | Required (`http_tokens = "required"`, hop limit: 2) | Required (`http_tokens = "required"`, hop limit: 2) |
| **Labels** | None defined by default | None defined by default | None defined by default |
| **Taints** | None defined by default | None defined by default | None defined by default |
| **Rolling Update Strategy**| Managed by EKS service | Managed by EKS service | Managed by EKS service |

---

## 6. EKS Add-ons

All three environments deploy the same set of add-ons and versions:

*   **CoreDNS**: `v1.11.1-eksbuild.9` (EKS Managed)
*   **kube-proxy**: `v1.30.0-eksbuild.3` (EKS Managed)
*   **VPC CNI**: `v1.18.1-eksbuild.3` (EKS Managed)
*   **EBS CSI Driver**: `v1.30.0-eksbuild.1` (EKS Managed, utilizes IRSA role)
*   **Metrics Server**: `3.12.1` (Helm Chart)
*   **AWS Load Balancer Controller**: `1.8.1` (Helm Chart, utilizes IRSA role)
*   **Cluster Autoscaler**: `9.37.0` (Helm Chart, utilizes IRSA role)

---

## 7. Container Registry

| Parameter | DEV | STAGE | PROD |
| :--- | :--- | :--- | :--- |
| **ECR Repository Count** | 8 | 8 | 8 |
| **Repository Names** | `cloud-foundation-{env}-[authlogin / order / ro / warehouse / rma / scheduler / reverseproxy / centralsignalrhub]` | Same repositories with `-stage-` namespace | Same repositories with `-prod-` namespace |
| **Image Scanning** | Enabled (`scan_on_push = true`) | Enabled (`scan_on_push = true`) | Enabled (`scan_on_push = true`) |
| **Encryption** | Yes (KMS using ECR KMS Key) | Yes (KMS using ECR KMS Key) | Yes (KMS using ECR KMS Key) |
| **Lifecycle Policies** | Prunes untagged >14 days; limits tagged to 30 | Prunes untagged >14 days; limits tagged to 30 | Prunes untagged >14 days; limits tagged to 30 |

---

## 8. Monitoring

| Parameter | DEV | STAGE | PROD |
| :--- | :--- | :--- | :--- |
| **CloudWatch EKS Logs** | Enabled, 30 Days Retention | Enabled, 90 Days Retention | Enabled, 365 Days Retention |
| **Flow Logs** | Enabled, 30 Days Retention | Enabled, 90 Days Retention | Enabled, 365 Days Retention |
| **Container Insights** | Not defined in Terraform | Not defined in Terraform | Not defined in Terraform |
| **Metrics** | Collected via Metrics Server | Collected via Metrics Server | Collected via Metrics Server |
| **Logging Encryption** | Yes (KMS CloudWatch key) | Yes (KMS CloudWatch key) | Yes (KMS CloudWatch key) |

---

## 9. Tags

All environments share the same baseline keys, with environment-specific values:

| Tag Key | DEV Value | STAGE Value | PROD Value |
| :--- | :--- | :--- | :--- |
| **Project** | `"cloud-foundation"` | `"cloud-foundation"` | `"cloud-foundation"` |
| **Environment** | `"dev"` | `"stage"` | `"prod"` |
| **Application** | `"Infrastructure"` | `"Infrastructure"` | `"Infrastructure"` |
| **Owner** | `"Platform-Team"` | `"Platform-Team"` | `"Platform-Team"` |
| **ManagedBy** | `"Terraform"` | `"Terraform"` | `"Terraform"` |
| **CostCenter** | `"Engineering"` | `"Engineering"` | `"Engineering"` |
| **Compliance** | `"HIPAA"` | `"HIPAA"` | `"HIPAA"` |
| **DataClassification**| `"Confidential"` | `"Confidential"` | `"Confidential"` |
| **Backup** | `"Enabled"` | `"Enabled"` | `"Enabled"` |

---

## 10. Cost Comparison

Estimates reflect the differences in sizing and configurations. This section outlines the monthly cost estimates for billable services, followed by a comparative overview of **Billable (Without Free)** and **Non-Billable (Free)** resources.

### Monthly Estimated Cost Table (Billable Resources Only)

| Service / Component | DEV (Monthly) | STAGE (Monthly) | PROD (Monthly) | Billing Detail / Cost Drivers |
| :--- | :--- | :--- | :--- | :--- |
| **NAT Gateway** | ~$32.85 | ~$32.85 | **~$98.55** | Dev/Stage: 1 NAT GW; Prod: 3 NAT GWs (+ ~$65.70/month in Prod). |
| **EKS Control Plane** | ~$73.00 | ~$73.00 | ~$73.00 | Flat fee of $0.10/hour across all environments. |
| **EC2 Worker Nodes** | ~$78.00 | ~$174.00 | **~$350.00** | Dev: 2 On-Demand + 2 Spot; Stage: 2 On-Demand + 3 Spot; Prod: 5 On-Demand (`m6i.large`). |
| **EBS Storage** | ~$16.00 | ~$20.00 | **~$20.00** | 50GB gp3 storage per node (~$0.08/GB/month = $4/node). |
| **KMS Keys** | ~$3.00 | ~$3.00 | ~$3.00 | 3 customer managed keys ($1/key/month). |
| **CloudWatch Storage**| Low (30-day cap) | Medium (90-day cap) | **High (365-day cap)** | Logs stored for 1 year are significantly more expensive. |
| **VPC Endpoints** | ~$65.00 | ~$65.00 | ~$65.00 | 9 interface endpoints mapped to 3 subnets in all. |
| **Estimated Total** | **~$267.85/mo**| **~$370.85/mo**| **~$609.55/mo**| *Does not include data processing or transfer fees.* |

*Services increasing cost in PROD*: NAT Gateways (3 vs 1), EC2 Nodes (5 On-Demand vs Spot blend), CloudWatch Log Storage (365 days vs 30/90).

### Overall Resource Type Breakdown (With and Without Free Services)

| Resource Metric | DEV | STAGE | PROD | Cost Status |
| :--- | :---: | :---: | :---: | :--- |
| **EKS Cluster** | 1 | 1 | 1 | **Billable** ($0.10/hour) |
| **KMS Keys** | 3 | 3 | 3 | **Billable** ($1/key/month) |
| **ECR Repositories** | 8 | 8 | 8 | **Billable** ($0.10/GB/month storage) |
| **VPC Interface Endpoints** | 9 | 9 | 9 | **Billable** (~$0.012/hour per AZ connection) |
| **NAT Gateways** | 1 | 1 | 3 | **Billable** (~$0.045/hour + processing) |
| **EC2 Worker Instances** | 4 | 5 | 5 | **Billable** (Varies by instance type/Spot vs On-Demand) |
| **EBS Volumes (gp3)** | 4 | 5 | 5 | **Billable** ($0.08/GB/month) |
| **VPC Flow Logs Ingestion** | 1 | 1 | 1 | **Billable** (Volume based storage/ingestion) |
| **VPC** | 1 | 1 | 1 | Free |
| **Subnets** | 9 | 9 | 9 | Free |
| **Internet Gateway** | 1 | 1 | 1 | Free |
| **Route Tables** | 3 | 3 | 5 | Free |
| **Route Table Associations** | 9 | 9 | 9 | Free |
| **Network ACLs** | 3 | 3 | 3 | Free |
| **Security Groups** | 6 | 6 | 6 | Free |
| **DB Subnet Group** | 1 | 1 | 1 | Free |
| **KMS Aliases** | 3 | 3 | 3 | Free |
| **IAM Roles** | 6 | 6 | 6 | Free |
| **IAM Policies** | 2 | 2 | 2 | Free |
| **IAM Attachments** | 10 | 10 | 10 | Free (9 role attachments + 1 inline flow log policy) |
| **OIDC Provider** | 1 | 1 | 1 | Free |
| **Launch Templates** | 2 | 2 | 2 | Free |
| **EKS Add-ons** | 4 | 4 | 4 | Free (Software integrations managed by EKS) |
| **Helm Releases** | 3 | 3 | 3 | Free (Software controllers managed via Helm) |
| **S3 Gateway Endpoint** | 1 | 1 | 1 | Free |
| **S3 Route Table Associations**| 3 | 3 | 5 | Free |
| **Total Billable Services Count**| **30** | **32** | **35** | **Overall Active AWS Billing Units** |
| **Total Free Services Count** | **67** | **67** | **69** | **Overall Non-Billing Resources** |
| **Overall Total Resources** | **97** | **99** | **104** | **Combined Active Stack Components** |

---

## 11. High Availability (HA)

| HA Component | DEV | STAGE | PROD |
| :--- | :--- | :--- | :--- |
| **AZ Architecture** | Multi-AZ (3 public, private, DB subnets) | Multi-AZ (3 public, private, DB subnets) | Multi-AZ (3 public, private, DB subnets) |
| **NAT Strategy** | Single NAT Gateway (Shared). *Single point of failure.* | Single NAT Gateway (Shared). *Single point of failure.* | Dedicated NAT Gateway per AZ. *No cross-AZ NAT failure propagation.* |
| **Node Distribution** | Distributed across 3 private subnets | Distributed across 3 private subnets | Distributed across 3 private subnets |
| **Control Plane** | Managed HA control plane by AWS EKS | Managed HA control plane by AWS EKS | Managed HA control plane by AWS EKS |
| **Endpoint Redundancy**| Mapped across 3 private subnets | Mapped across 3 private subnets | Mapped across 3 private subnets |
| **Fault Tolerance** | Low (VPC NAT failure halts outbound node connection) | Low (VPC NAT failure halts outbound node connection) | High (Full AZ failure isolated; NAT and nodes failover seamlessly) |

---

## 12. Security Comparison

| Security Control | DEV | STAGE | PROD |
| :--- | :--- | :--- | :--- |
| **IMDSv2 Enforce** | Yes (`http_tokens = "required"`, hop limit: 2) | Yes (`http_tokens = "required"`, hop limit: 2) | Yes (`http_tokens = "required"`, hop limit: 2) |
| **gp3 Encryption** | Yes (KMS using EKS Key) | Yes (KMS using EKS Key) | Yes (KMS using EKS Key) |
| **KMS Encryption** | Yes (EKS Secrets, ECR repos, CloudWatch Logs group) | Yes (EKS Secrets, ECR repos, CloudWatch Logs group) | Yes (EKS Secrets, ECR repos, CloudWatch Logs group) |
| **IRSA / OIDC** | Yes (EBS CSI, LB Controller, Autoscaler role credentials) | Yes (EBS CSI, LB Controller, Autoscaler role credentials) | Yes (EBS CSI, LB Controller, Autoscaler role credentials) |
| **Private Network** | EKS endpoint public access disabled; private access enabled | EKS endpoint public access disabled; private access enabled | EKS endpoint public access disabled; private access enabled |
| **Flow Logs** | Yes, 30 days retention | Yes, 90 days retention | Yes, 365 days retention |
| **Security Groups** | Default denies all; explicit rules for ALB, nodes, DB | Default denies all; explicit rules for ALB, nodes, DB | Default denies all; explicit rules for ALB, nodes, DB |

---

## 13. Resource Inventory

| AWS Service / Resource (Terraform Block) | DEV | STAGE | PROD |
| :--- | :---: | :---: | :---: |
| `aws_vpc` | 1 | 1 | 1 |
| `aws_subnet` | 9 | 9 | 9 |
| `aws_route_table` | 3 | 3 | 5 |
| `aws_nat_gateway` | 1 | 1 | 3 |
| `aws_eip` | 1 | 1 | 3 |
| `aws_security_group` | 6 | 6 | 6 |
| `aws_network_acl` | 3 | 3 | 3 |
| `aws_vpc_endpoint` | 10 | 10 | 10 |
| `aws_cloudwatch_log_group` | 2 | 2 | 2 |
| `aws_kms_key` | 3 | 3 | 3 |
| `aws_iam_role` | 6 | 6 | 6 |
| `aws_iam_policy` | 2 | 2 | 2 |
| `aws_iam_openid_connect_provider` | 1 | 1 | 1 |
| `aws_eks_cluster` | 1 | 1 | 1 |
| `aws_launch_template` | 2 | 2 | 2 |
| `aws_eks_node_group` | 2 | 2 | 2 |
| `aws_ecr_repository` | 8 | 8 | 8 |
| `aws_eks_addon` (CoreDNS, kube-proxy, VPC CNI, EBS CSI)| 4 | 4 | 4 |
| `helm_release` (Metrics Server, LB Ctrl, Autoscaler) | 3 | 3 | 3 |

---

## 14. Difference Summary

| Feature / Setting | DEV | STAGE | PROD | Reason for Difference |
| :--- | :--- | :--- | :--- | :--- |
| **NAT Gateway Count** | 1 | 1 | 3 | **HA vs Cost**: Dev/Stage accept single-point-of-failure to optimize cost. Prod requires multi-AZ gateway redundancy. |
| **Private Route Tables**| 1 | 1 | 3 | **Outbound Routing**: Dev/Stage route to 1 NAT; Prod routes each AZ private subnet to its own local NAT Gateway. |
| **System Node Instance**| `t3.medium` | `t3.large` | `m6i.large` | **Performance**: Production requires dedicated enterprise cores (`m6i`) over burstable (`t3`) compute. |
| **App Node Instance** | `t3.medium` | `t3.large` | `m6i.large` | **Performance**: Application scaling and microservice stability requires production-grade workloads. |
| **App Node Capacity** | `SPOT` | `SPOT` | `ON_DEMAND` | **SLA / Availability**: Dev/Stage optimize cost via Spot instances. Prod uses On-Demand to avoid unexpected Spot terminations. |
| **Node scaling limits** | Min: 1, Max: 5 | Min: 2, Max: 6 | Min: 3, Max: 10 | **Scalability / Demand**: Production handles larger load surges and enforces high-availability scheduling policies. |
| **Logs Retention** | 30 Days | 90 Days | 365 Days | **HIPAA Compliance**: Production audit logs are retained longer to meet regulatory guidelines while saving cost in non-prod. |

---

## 15. Production Readiness Score

Scores evaluate how close the configuration aligns with AWS enterprise standards (0-100 scale):

| Category | DEV | STAGE | PROD | Analysis |
| :--- | :--- | :--- | :--- | :--- |
| **Security** | 94 | 94 | **94** | Outstanding: Private endpoints, encrypted disks, rotated keys, and private EKS API endpoints are uniform. |
| **Availability** | 60 | 60 | **92** | Prod uses 3 NAT Gateways and On-Demand nodes, eliminating Dev's single NAT and Spot eviction risks. |
| **Scalability** | 80 | 85 | **95** | Prod supports up to 10 application nodes on `m6i.large` dedicated cores. |
| **Monitoring** | 70 | 75 | **85** | Prod logs are retained for 365 days, but Container Insights and automated alarms are missing. |
| **Cost Optimization**| 95 | 92 | **75** | Dev/Stage use Spot and Single NAT. Prod prioritizes HA over cost. |
| **Disaster Recovery**| 40 | 40 | **40** | Empty velero scaffold module; no database replication or cluster DR config is active. |
| **Compliance** | 92 | 92 | **92** | Encryption and flow logs are active, but retention and policy limits require auditing. |

---

### Overall Environment Scores
*   **Overall DEV Score**: **76/100** (Highly cost-efficient, good baseline security, low availability)
*   **Overall STAGE Score**: **77/100** (Larger node sizes, Spot risk remains, single NAT bottleneck)
*   **Overall PROD Score**: **82/100** (High availability and network redundancy are solid, but lacks DR/backup engines and monitoring dashboards)

---

## Missing Production Best Practices & Recommendations

1.  **Disaster Recovery Plan (Scaffold Gaps)**:
    *   *Finding*: The Velero module (`modules/velero`) is empty, meaning there are no automated backups of the cluster configuration or persistent volumes in S3.
    *   *Recommendation*: Implement Velero deployment and S3 backup targets, and configure RDS automated backups/replication.
2.  **Audit Logs Long-Term Storage**:
    *   *Finding*: Prod CloudWatch logs are deleted after 365 days. HIPAA/HITECH regulations often require audit logs to be retained for **6 to 7 years**.
    *   *Recommendation*: Configure S3 bucket exports or Kinesis Firehose to stream CloudWatch logs to S3 Glacier with a compliance Vault Lock.
3.  **Cross-Account Key Policy Constraints**:
    *   *Finding*: KMS Key policies permit the root account full access (`arn:aws:iam::account-id:root`).
    *   *Recommendation*: Refine key policies to restrict use to specific IAM roles (EKS admin, log group services) and prevent accidental cross-account modifications.
