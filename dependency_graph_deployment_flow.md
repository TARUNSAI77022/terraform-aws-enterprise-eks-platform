# Terraform Dependency Graph & Deployment Flow Analysis

This report presents a comprehensive dependency graph and execution flow analysis of the **AWS Enterprise EKS Platform** project. It maps the precise execution sequences, resource-level dependencies, and error boundaries during initialization, planning, deployment, and destruction.

---

## 1. TERRAFORM EXECUTION PHASES FLOW

### 1.1 `terraform init`
1.  **Backend Initialization**: Reads `backend.tf` in the active environment directory (`dev`, `stage`, or `prod`). Authenticates with the S3 backend and establishes a lock on the DynamoDB state locking table (`terraform-lock`).
2.  **Plugin Discovery & Download**: Reads the required providers block from `versions.tf` / `provider.tf`. Downloads the matching versions of:
    *   `hashicorp/aws` (AWS Provider)
    *   `hashicorp/kubernetes` (Kubernetes Provider)
    *   `hashicorp/helm` (Helm Provider)
    *   `hashicorp/tls` (TLS Provider)
3.  **Module Registration**: Downloads and links the local directories referenced in the `module` blocks under `env/*/main.tf` to `.terraform/modules/`.

### 1.2 `terraform plan`
1.  **State Refresh**: Contacts AWS APIs to fetch the current, real-world state of all resources tracked in the state file.
2.  **Variable Parsing**: Evaluates local values (`locals`) and merges variables from `variables.tf` (and any variables passed via environment or files).
3.  **Graph Construction**: Builds the internal resource dependency graph.
4.  **Dry Run Execution**: Simulates resource creation, modification, and replacement, checking logic and syntax. Generates a planned delta (Add/Change/Destroy).

### 1.3 `terraform apply`
1.  **Lock State**: Obtains a state lock in DynamoDB to prevent concurrent executions.
2.  **Plan Review & Confirmation**: Presents the plan to the user.
3.  **Graph Traversal (Deployment Flow)**: Traverses the dependency graph in parallel paths. Resources without dependencies are created first, followed sequentially by dependent resources.
4.  **State Persistence**: Writes resource metadata (IDs, attributes) to the state file in S3 immediately after each API call completes.
5.  **Unlock State**: Releases the DynamoDB lock.

### 1.4 `terraform destroy`
1.  **Lock State**: Obtains the DynamoDB state lock.
2.  **Reverse Graph Traversal**: Reverses the dependency graph. Leaf nodes (resources that have no other resources depending on them, such as Helm releases) are destroyed first, followed by parent nodes, ending with root nodes (VPC, KMS keys).
3.  **State Clean Up**: Removes resource objects from the state file.
4.  **Unlock State**: Releases the lock.

---

## 2. COMPLETE RESOURCE CREATION ORDER (`terraform apply`)

The following is the exact sequential execution order followed by Terraform during `apply`. Multiple resources at the same dependency depth are created in parallel by Terraform's engine.

---

### Step 1
*   **Terraform Module**: `module.kms`
*   **Terraform Resource**: `aws_kms_key.eks`
*   **AWS Service**: Key Management Service (KMS)
*   **AWS Resource Name**: `cloud-foundation-{env}-kms-eks`
*   **Why it is created**: Provides cryptographic envelope encryption for Kubernetes Secrets.
*   **Depends On**: None
*   **Required By**: `aws_kms_alias.eks`, `aws_eks_cluster.this`, `aws_launch_template.this`
*   **Billing**: **Billable ($1.00/month)**
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No (subsequent EKS control plane and nodes cannot deploy)
*   **Whether partially created resources remain**: No (if creation fails at API level, nothing is left; if it succeeds but next steps fail, key remains)

---

### Step 2
*   **Terraform Module**: `module.kms`
*   **Terraform Resource**: `aws_kms_key.cloudwatch`
*   **AWS Service**: Key Management Service (KMS)
*   **AWS Resource Name**: `cloud-foundation-{env}-kms-cloudwatch`
*   **Why it is created**: Encrypts EKS cluster control plane logs at rest in CloudWatch.
*   **Depends On**: None
*   **Required By**: `aws_kms_alias.cloudwatch`, `aws_cloudwatch_log_group.eks`
*   **Billing**: **Billable ($1.00/month)**
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 3
*   **Terraform Module**: `module.kms`
*   **Terraform Resource**: `aws_kms_key.ecr`
*   **AWS Service**: Key Management Service (KMS)
*   **AWS Resource Name**: `cloud-foundation-{env}-kms-ecr`
*   **Why it is created**: Encrypts Docker image layers stored in ECR repositories.
*   **Depends On**: None
*   **Required By**: `aws_kms_alias.ecr`, `aws_ecr_repository.this`
*   **Billing**: **Billable ($1.00/month)**
*   **Whether failure here stops the deployment**: Yes (stops container registry provisioning)
*   **Whether Terraform continues after failure**: Yes, for unrelated VPC components; No for ECR and EKS deployments.
*   **Whether partially created resources remain**: No

---

### Step 4
*   **Terraform Module**: `module.kms`
*   **Terraform Resource**: `aws_kms_alias.eks`
*   **AWS Service**: Key Management Service (KMS)
*   **AWS Resource Name**: `alias/cloud-foundation-{env}-eks`
*   **Why it is created**: Friendly name binding for EKS Key.
*   **Depends On**: `aws_kms_key.eks`
*   **Required By**: None
*   **Billing**: Free
*   **Whether failure here stops the deployment**: No
*   **Whether Terraform continues after failure**: Yes (EKS can use raw Key ARN)
*   **Whether partially created resources remain**: N/A

---

### Step 5
*   **Terraform Module**: `module.kms`
*   **Terraform Resource**: `aws_kms_alias.cloudwatch`
*   **AWS Service**: Key Management Service (KMS)
*   **AWS Resource Name**: `alias/cloud-foundation-{env}-cloudwatch`
*   **Why it is created**: Friendly name binding for CloudWatch Key.
*   **Depends On**: `aws_kms_key.cloudwatch`
*   **Required By**: None
*   **Billing**: Free
*   **Whether failure here stops the deployment**: No
*   **Whether Terraform continues after failure**: Yes
*   **Whether partially created resources remain**: N/A

---

### Step 6
*   **Terraform Module**: `module.kms`
*   **Terraform Resource**: `aws_kms_alias.ecr`
*   **AWS Service**: Key Management Service (KMS)
*   **AWS Resource Name**: `alias/cloud-foundation-{env}-ecr`
*   **Why it is created**: Friendly name binding for ECR Key.
*   **Depends On**: `aws_kms_key.ecr`
*   **Required By**: None
*   **Billing**: Free
*   **Whether failure here stops the deployment**: No
*   **Whether Terraform continues after failure**: Yes
*   **Whether partially created resources remain**: N/A

---

### Step 7
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_vpc.main`
*   **AWS Service**: Amazon VPC
*   **AWS Resource Name**: `cloud-foundation-{env}-vpc`
*   **Why it is created**: Primary logical network partition.
*   **Depends On**: None
*   **Required By**: Subnets, Gateways, Route Tables, Security Groups, Flow Logs
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No (VPC is the root dependency)
*   **Whether partially created resources remain**: No

---

### Step 8
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_default_security_group.default`
*   **AWS Service**: EC2 Security Group
*   **AWS Resource Name**: `default`
*   **Why it is created**: Hardens the default VPC security group to reject all ingress/egress.
*   **Depends On**: `aws_vpc.main`
*   **Required By**: None
*   **Billing**: Free
*   **Whether failure here stops the deployment**: No
*   **Whether Terraform continues after failure**: Yes
*   **Whether partially created resources remain**: N/A (AWS auto-creates the SG; Terraform only updates rules)

---

### Step 9
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_internet_gateway.igw`
*   **AWS Service**: VPC Gateway
*   **AWS Resource Name**: `cloud-foundation-{env}-igw`
*   **Why it is created**: Enables public routing for VPC ingress/egress.
*   **Depends On**: `aws_vpc.main`
*   **Required By**: `aws_eip.nat`, `aws_nat_gateway.nat`, `aws_route_table.public`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No (blocks outbound routing required for NAT/nodes)
*   **Whether partially created resources remain**: No

---

### Step 10
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_subnet.public` (count = 3)
*   **AWS Service**: VPC Subnet
*   **AWS Resource Name**: `cloud-foundation-{env}-subnet-public-ap-south-1[a/b/c]`
*   **Why it is created**: Hosts NAT Gateways and external ALBs.
*   **Depends On**: `aws_vpc.main`
*   **Required By**: `aws_nat_gateway.nat`, `aws_route_table_association.public`, network ACLs
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: Yes (if subnet A succeeds but B fails, A remains)

---

### Step 11
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_subnet.private` (count = 3)
*   **AWS Service**: VPC Subnet
*   **AWS Resource Name**: `cloud-foundation-{env}-subnet-private-app-ap-south-1[a/b/c]`
*   **Why it is created**: Private application zone hosting EKS worker nodes.
*   **Depends On**: `aws_vpc.main`
*   **Required By**: `aws_eks_cluster.this`, `aws_eks_node_group.this`, `aws_vpc_endpoint.interface`, route associations
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: Yes

---

### Step 12
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_subnet.database` (count = 3)
*   **AWS Service**: VPC Subnet
*   **AWS Resource Name**: `cloud-foundation-{env}-subnet-database-ap-south-1[a/b/c]`
*   **Why it is created**: Isolated subnet zone for DB engines.
*   **Depends On**: `aws_vpc.main`
*   **Required By**: `aws_db_subnet_group.database`, route associations, DB NACL
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes (stops DB deployment)
*   **Whether Terraform continues after failure**: Yes, for compute/EKS (since EKS doesn't directly depend on DB subnets)
*   **Whether partially created resources remain**: Yes

---

### Step 13
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_db_subnet_group.database`
*   **AWS Service**: RDS Subnet Group
*   **AWS Resource Name**: `cloud-foundation-{env}-db-subnet-group`
*   **Why it is created**: Groups database subnets for Multi-AZ RDS configurations.
*   **Depends On**: `aws_subnet.database`
*   **Required By**: None (referenced by future DB resource)
*   **Billing**: Free
*   **Whether failure here stops the deployment**: No
*   **Whether Terraform continues after failure**: Yes
*   **Whether partially created resources remain**: No

---

### Step 14
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_eip.nat` (count = 1 in Dev/Stage, 3 in Prod)
*   **AWS Service**: EC2 Elastic IP
*   **AWS Resource Name**: `cloud-foundation-{env}-nat-eip-ap-south-1[a/b/c]`
*   **Why it is created**: Static IP allocation for NAT Gateway.
*   **Depends On**: `aws_internet_gateway.igw`
*   **Required By**: `aws_nat_gateway.nat`
*   **Billing**: Free (when attached to active NAT gateway)
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No (NAT gateway cannot deploy)
*   **Whether partially created resources remain**: Yes

---

### Step 15
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_nat_gateway.nat` (count = 1 in Dev/Stage, 3 in Prod)
*   **AWS Service**: VPC NAT Gateway
*   **AWS Resource Name**: `cloud-foundation-{env}-nat-gw-ap-south-1[a/b/c]`
*   **Why it is created**: Enables private application subnets to access public endpoints.
*   **Depends On**: `aws_eip.nat`, `aws_subnet.public`, `aws_internet_gateway.igw`
*   **Required By**: `aws_route_table.private`
*   **Billing**: **Billable (~$0.045/hour + data processing)**
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No (nodes cannot pull updates or join EKS control plane)
*   **Whether partially created resources remain**: Yes

---

### Step 16
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_route_table.public`
*   **AWS Service**: VPC Route Table
*   **AWS Resource Name**: `cloud-foundation-{env}-rt-public`
*   **Why it is created**: Routes traffic from public subnets to the Internet Gateway.
*   **Depends On**: `aws_vpc.main`, `aws_internet_gateway.igw`
*   **Required By**: `aws_route_table_association.public`, `aws_vpc_endpoint.s3`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 17
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_route_table.private` (count = 1 in Dev/Stage, 3 in Prod)
*   **AWS Service**: VPC Route Table
*   **AWS Resource Name**: `cloud-foundation-{env}-rt-private-[shared/AZ]`
*   **Why it is created**: Routes traffic from private subnets to the NAT Gateway.
*   **Depends On**: `aws_vpc.main`, `aws_nat_gateway.nat`
*   **Required By**: `aws_route_table_association.private`, `aws_vpc_endpoint.s3`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: Yes

---

### Step 18
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_route_table.database`
*   **AWS Service**: VPC Route Table
*   **AWS Resource Name**: `cloud-foundation-{env}-rt-database`
*   **Why it is created**: Local isolated route table for databases.
*   **Depends On**: `aws_vpc.main`
*   **Required By**: `aws_route_table_association.database`, `aws_vpc_endpoint.s3`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 19
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_route_table_association.public` (count = 3)
*   **AWS Service**: Route Table Association
*   **AWS Resource Name**: None (Unified mapping in console)
*   **Why it is created**: Links public subnets to public route table.
*   **Depends On**: `aws_subnet.public`, `aws_route_table.public`
*   **Required By**: None
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: Yes

---

### Step 20
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_route_table_association.private` (count = 3)
*   **AWS Service**: Route Table Association
*   **AWS Resource Name**: None
*   **Why it is created**: Links private subnets to private route tables.
*   **Depends On**: `aws_subnet.private`, `aws_route_table.private`
*   **Required By**: None
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: Yes

---

### Step 21
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_route_table_association.database` (count = 3)
*   **AWS Service**: Route Table Association
*   **AWS Resource Name**: None
*   **Why it is created**: Links database subnets to database route table.
*   **Depends On**: `aws_subnet.database`, `aws_route_table.database`
*   **Required By**: None
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: Yes

---

### Step 22
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_network_acl.public`
*   **AWS Service**: VPC Network ACL
*   **AWS Resource Name**: `cloud-foundation-{env}-nacl-public`
*   **Why it is created**: Enforces firewall rules at the public subnet boundary.
*   **Depends On**: `aws_vpc.main`, `aws_subnet.public`
*   **Required By**: None
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 23
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_network_acl.private`
*   **AWS Service**: VPC Network ACL
*   **AWS Resource Name**: `cloud-foundation-{env}-nacl-private`
*   **Why it is created**: Enforces firewall rules at private app subnets.
*   **Depends On**: `aws_vpc.main`, `aws_subnet.private`
*   **Required By**: None
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 24
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_network_acl.database`
*   **AWS Service**: VPC Network ACL
*   **AWS Resource Name**: `cloud-foundation-{env}-nacl-database`
*   **Why it is created**: Restricts DB access strictly to VPC internal ports.
*   **Depends On**: `aws_vpc.main`, `aws_subnet.database`
*   **Required By**: None
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 25
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_security_group.vpc_endpoints`
*   **AWS Service**: Security Group
*   **AWS Resource Name**: `cloud-foundation-{env}-vpc-endpoints-sg`
*   **Why it is created**: Restricts endpoint access to HTTPS from VPC CIDR.
*   **Depends On**: `aws_vpc.main`
*   **Required By**: `aws_vpc_endpoint.interface`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 26
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_vpc_endpoint.s3`
*   **AWS Service**: VPC Gateway Endpoint
*   **AWS Resource Name**: `cloud-foundation-{env}-vpce-s3`
*   **Why it is created**: Private S3 routing for pulling ECR layers.
*   **Depends On**: `aws_vpc.main`
*   **Required By**: `aws_vpc_endpoint_route_table_association.s3`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 27
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_vpc_endpoint_route_table_association.s3` (count = 3 in Dev/Stage, 5 in Prod)
*   **AWS Service**: Gateway Route Table Association
*   **AWS Resource Name**: None
*   **Why it is created**: Injects S3 private endpoint routes into subnet route tables.
*   **Depends On**: `aws_vpc_endpoint.s3`, route tables
*   **Required By**: None
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: Yes

---

### Step 28
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_vpc_endpoint.interface` (count = 9)
*   **AWS Service**: VPC Interface Endpoint (PrivateLink)
*   **AWS Resource Name**: `cloud-foundation-{env}-vpce-[service]`
*   **Why it is created**: Keeps API call networks internal for compliance.
*   **Depends On**: `aws_vpc.main`, `aws_subnet.private`, `aws_security_group.vpc_endpoints`
*   **Required By**: None (used dynamically by EKS / AWS SDKs)
*   **Billing**: **Billable (~$0.012/hour per AZ mapping = 9 * 3 AZs = 27 mappings * $0.012 = ~$0.324/hour total + data processing)**
*   **Whether failure here stops the deployment**: No (system can technically resolve via public NAT, but violates HIPAA isolation layout)
*   **Whether Terraform continues after failure**: Yes
*   **Whether partially created resources remain**: Yes

---

### Step 29
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_cloudwatch_log_group.vpc_flow_logs`
*   **AWS Service**: CloudWatch Logs
*   **AWS Resource Name**: `/aws/vpc-flow-logs/cloud-foundation-{env}`
*   **Why it is created**: Flow logs storage vault.
*   **Depends On**: None
*   **Required By**: `aws_flow_log.main`
*   **Billing**: **Billable (Storage: $0.03/GB/month)**
*   **Whether failure here stops the deployment**: No
*   **Whether Terraform continues after failure**: Yes (Flow logs step fails, but doesn't block computing/EKS)
*   **Whether partially created resources remain**: No

---

### Step 30
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_iam_role.vpc_flow_log_role`
*   **AWS Service**: AWS IAM
*   **AWS Resource Name**: `cloud-foundation-{env}-vpc-flow-logs-role`
*   **Why it is created**: IAM role allowing Flow logs service to access logs.
*   **Depends On**: None
*   **Required By**: `aws_flow_log.main`, `aws_iam_role_policy.vpc_flow_log_policy`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: No
*   **Whether Terraform continues after failure**: Yes
*   **Whether partially created resources remain**: No

---

### Step 31
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_iam_role_policy.vpc_flow_log_policy`
*   **AWS Service**: AWS IAM
*   **AWS Resource Name**: `cloud-foundation-{env}-vpc-flow-logs-policy`
*   **Why it is created**: IAM Policy detailing permitted CloudWatch API actions.
*   **Depends On**: `aws_iam_role.vpc_flow_log_role`, `aws_cloudwatch_log_group.vpc_flow_logs`
*   **Required By**: `aws_flow_log.main`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: No
*   **Whether Terraform continues after failure**: Yes
*   **Whether partially created resources remain**: No

---

### Step 32
*   **Terraform Module**: `module.vpc`
*   **Terraform Resource**: `aws_flow_log.main`
*   **AWS Service**: VPC Flow Log
*   **AWS Resource Name**: `cloud-foundation-{env}-vpc-flow-logs`
*   **Why it is created**: Captures flow metadata for compliance.
*   **Depends On**: `aws_vpc.main`, `aws_cloudwatch_log_group.vpc_flow_logs`, `aws_iam_role.vpc_flow_log_role`, `aws_iam_role_policy.vpc_flow_log_policy`
*   **Required By**: None
*   **Billing**: **Billable (vending charges)**
*   **Whether failure here stops the deployment**: No
*   **Whether Terraform continues after failure**: Yes
*   **Whether partially created resources remain**: No

---

### Step 33
*   **Terraform Module**: `module.security_groups`
*   **Terraform Resource**: `aws_security_group.alb_sg`
*   **AWS Service**: Security Group
*   **AWS Resource Name**: `cloud-foundation-{env}-alb-sg`
*   **Why it is created**: Manages port 80/443 public entry points.
*   **Depends On**: VPC (via `module.vpc.vpc_id`)
*   **Required By**: `aws_security_group.app_node_sg`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 34
*   **Terraform Module**: `module.security_groups`
*   **Terraform Resource**: `aws_security_group.app_node_sg`
*   **AWS Service**: Security Group
*   **AWS Resource Name**: `cloud-foundation-{env}-app-node-sg`
*   **Why it is created**: Node host SG.
*   **Depends On**: `aws_security_group.alb_sg`
*   **Required By**: `aws_security_group.db_sg`, `aws_security_group.eks_cluster_sg`, `aws_launch_template.this`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 35
*   **Terraform Module**: `module.security_groups`
*   **Terraform Resource**: `aws_security_group.ssm_bastion_sg`
*   **AWS Service**: Security Group
*   **AWS Resource Name**: `cloud-foundation-{env}-ssm-bastion-sg`
*   **Why it is created**: Secures the Bastion instance.
*   **Depends On**: VPC
*   **Required By**: `aws_security_group.db_sg`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: No
*   **Whether Terraform continues after failure**: Yes
*   **Whether partially created resources remain**: No

---

### Step 36
*   **Terraform Module**: `module.security_groups`
*   **Terraform Resource**: `aws_security_group.db_sg`
*   **AWS Service**: Security Group
*   **AWS Resource Name**: `cloud-foundation-{env}-db-sg`
*   **Why it is created**: Secures the database from node/bastion access only.
*   **Depends On**: `aws_security_group.app_node_sg`, `aws_security_group.ssm_bastion_sg`
*   **Required By**: None
*   **Billing**: Free
*   **Whether failure here stops the deployment**: No
*   **Whether Terraform continues after failure**: Yes
*   **Whether partially created resources remain**: No

---

### Step 37
*   **Terraform Module**: `module.security_groups`
*   **Terraform Resource**: `aws_security_group.eks_cluster_sg`
*   **AWS Service**: Security Group
*   **AWS Resource Name**: `cloud-foundation-{env}-eks-cluster-sg`
*   **Why it is created**: Secures EKS control plane interface.
*   **Depends On**: `aws_security_group.app_node_sg`
*   **Required By**: `aws_eks_cluster.this`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 38
*   **Terraform Module**: `module.iam`
*   **Terraform Resource**: `aws_iam_role.eks_cluster`
*   **AWS Service**: AWS IAM
*   **AWS Resource Name**: `cloud-foundation-{env}-eks-cluster-role`
*   **Why it is created**: Cluster plane IAM execution identity.
*   **Depends On**: None
*   **Required By**: Attachments, `aws_eks_cluster.this`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 39
*   **Terraform Module**: `module.iam`
*   **Terraform Resource**: `aws_iam_role_policy_attachment.eks_cluster_policy`
*   **AWS Service**: IAM Attachment
*   **AWS Resource Name**: None
*   **Why it is created**: Attaches core EKS control plane policy.
*   **Depends On**: `aws_iam_role.eks_cluster`
*   **Required By**: `aws_eks_cluster.this`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: Yes

---

### Step 40
*   **Terraform Module**: `module.iam`
*   **Terraform Resource**: `aws_iam_role_policy_attachment.eks_vpc_resource_controller`
*   **AWS Service**: IAM Attachment
*   **AWS Resource Name**: None
*   **Why it is created**: Attaches ENI VPC resource manager policy.
*   **Depends On**: `aws_iam_role.eks_cluster`
*   **Required By**: `aws_eks_cluster.this`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: Yes

---

### Step 41
*   **Terraform Module**: `module.iam`
*   **Terraform Resource**: `aws_iam_role.node_group`
*   **AWS Service**: AWS IAM
*   **AWS Resource Name**: `cloud-foundation-{env}-eks-node-role`
*   **Why it is created**: Compute nodes execution identity.
*   **Depends On**: None
*   **Required By**: Attachments, `aws_eks_node_group.this`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 42
*   **Terraform Module**: `module.iam`
*   **Terraform Resource**: `aws_iam_role_policy_attachment.node_worker_policy`
*   **AWS Service**: IAM Attachment
*   **AWS Resource Name**: None
*   **Why it is created**: Worker nodes policy.
*   **Depends On**: `aws_iam_role.node_group`
*   **Required By**: `aws_eks_node_group.this`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: Yes

---

### Step 43
*   **Terraform Module**: `module.iam`
*   **Terraform Resource**: `aws_iam_role_policy_attachment.node_cni_policy`
*   **AWS Service**: IAM Attachment
*   **AWS Resource Name**: None
*   **Why it is created**: VPC CNI networking permissions.
*   **Depends On**: `aws_iam_role.node_group`
*   **Required By**: `aws_eks_node_group.this`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: Yes

---

### Step 44
*   **Terraform Module**: `module.iam`
*   **Terraform Resource**: `aws_iam_role_policy_attachment.node_ecr_policy`
*   **AWS Service**: IAM Attachment
*   **AWS Resource Name**: None
*   **Why it is created**: ECR Read-Only permissions to pull application images.
*   **Depends On**: `aws_iam_role.node_group`
*   **Required By**: `aws_eks_node_group.this`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: Yes

---

### Step 45
*   **Terraform Module**: `module.iam`
*   **Terraform Resource**: `aws_iam_role_policy_attachment.node_ssm_policy`
*   **AWS Service**: IAM Attachment
*   **AWS Resource Name**: None
*   **Why it is created**: SSM Session Manager access.
*   **Depends On**: `aws_iam_role.node_group`
*   **Required By**: `aws_eks_node_group.this`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: Yes

---

### Step 46
*   **Terraform Module**: `module.cloudwatch`
*   **Terraform Resource**: `aws_cloudwatch_log_group.eks`
*   **AWS Service**: CloudWatch Logs
*   **AWS Resource Name**: `/aws/eks/cloud-foundation-{env}-eks/cluster`
*   **Why it is created**: Receives control plane telemetry.
*   **Depends On**: `module.kms.cloudwatch_kms_key_arn`
*   **Required By**: `aws_eks_cluster.this` (via explicit module dependency)
*   **Billing**: **Billable (Storage: $0.03/GB/month)**
*   **Whether failure here stops the deployment**: Yes (stops cluster creation)
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 47
*   **Terraform Module**: `module.ecr`
*   **Terraform Resource**: `aws_ecr_repository.this` (count = 8)
*   **AWS Service**: Elastic Container Registry
*   **AWS Resource Name**: `cloud-foundation-{env}-[authlogin / order / ro / warehouse / rma / scheduler / reverseproxy / centralsignalrhub]`
*   **Why it is created**: Host Docker repository folders.
*   **Depends On**: `module.kms.ecr_kms_key_arn`
*   **Required By**: `aws_ecr_lifecycle_policy.this`
*   **Billing**: **Billable (Storage: $0.10/GB/month)**
*   **Whether failure here stops the deployment**: No
*   **Whether Terraform continues after failure**: Yes
*   **Whether partially created resources remain**: Yes

---

### Step 48
*   **Terraform Module**: `module.ecr`
*   **Terraform Resource**: `aws_ecr_lifecycle_policy.this` (count = 8)
*   **AWS Service**: Elastic Container Registry
*   **AWS Resource Name**: Associated with ECR repositories
*   **Why it is created**: Automated cleanup rule matching rules 1 and 2.
*   **Depends On**: `aws_ecr_repository.this`
*   **Required By**: None
*   **Billing**: Free
*   **Whether failure here stops the deployment**: No
*   **Whether Terraform continues after failure**: Yes
*   **Whether partially created resources remain**: Yes

---

### Step 49
*   **Terraform Module**: `module.eks`
*   **Terraform Resource**: `aws_eks_cluster.this`
*   **AWS Service**: Elastic Kubernetes Service (EKS)
*   **AWS Resource Name**: `cloud-foundation-{env}-eks`
*   **Why it is created**: Baseline managed Kubernetes control plane.
*   **Depends On**: `module.iam.eks_cluster_role_arn`, subnets, `module.security_groups.eks_cluster_sg_id`, `module.kms.eks_kms_key_arn`, `module.cloudwatch.log_group_arn` (via depends_on)
*   **Required By**: `aws_iam_openid_connect_provider.this`, `aws_eks_node_group.this`, addons, helm releases
*   **Billing**: **Billable ($0.10/hour)**
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No (unless API times out during creation, leaving a pending cluster in AWS)

---

### Step 50
*   **Terraform Module**: `module.eks`
*   **Terraform Resource**: `aws_iam_openid_connect_provider.this`
*   **AWS Service**: IAM OIDC Provider
*   **AWS Resource Name**: `cloud-foundation-{env}-eks-oidc-provider`
*   **Why it is created**: Federated connection identity provider for service accounts.
*   **Depends On**: `aws_eks_cluster.this`
*   **Required By**: IRSA IAM Roles (`aws_iam_role.ebs_csi`, `aws_lb_controller`, `cluster_autoscaler`)
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 51
*   **Terraform Module**: `module.iam`
*   **Terraform Resource**: `aws_iam_role.ebs_csi`
*   **AWS Service**: AWS IAM
*   **AWS Resource Name**: `cloud-foundation-{env}-ebs-csi-role`
*   **Why it is created**: EBS controller pod security context identity.
*   **Depends On**: `module.eks.oidc_provider_arn`, `module.eks.oidc_provider_url` (passed as inputs)
*   **Required By**: `aws_iam_role_policy_attachment.ebs_csi`, `aws_eks_addon.ebs_csi`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes (stops EBS driver)
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 52
*   **Terraform Module**: `module.iam`
*   **Terraform Resource**: `aws_iam_role_policy_attachment.ebs_csi`
*   **AWS Service**: IAM Attachment
*   **AWS Resource Name**: None
*   **Why it is created**: Binds EBS driver policies.
*   **Depends On**: `aws_iam_role.ebs_csi`
*   **Required By**: `aws_eks_addon.ebs_csi`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: Yes

---

### Step 53
*   **Terraform Module**: `module.iam`
*   **Terraform Resource**: `aws_iam_role.aws_lb_controller`
*   **AWS Service**: AWS IAM
*   **AWS Resource Name**: `cloud-foundation-{env}-aws-lb-controller-role`
*   **Why it is created**: ALB controller security context identity.
*   **Depends On**: OIDC provider outputs
*   **Required By**: `aws_iam_role_policy_attachment.aws_lb_controller`, `helm_release.aws_load_balancer_controller`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes (stops ALB provisioning controllers)
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 54
*   **Terraform Module**: `module.iam`
*   **Terraform Resource**: `aws_iam_policy.aws_load_balancer_controller`
*   **AWS Service**: IAM Policy
*   **AWS Resource Name**: `cloud-foundation-{env}-aws-lb-controller-policy`
*   **Why it is created**: Specific policy detailing EC2 load balancer provisioning actions.
*   **Depends On**: None
*   **Required By**: `aws_iam_role_policy_attachment.aws_lb_controller`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 55
*   **Terraform Module**: `module.iam`
*   **Terraform Resource**: `aws_iam_role_policy_attachment.aws_lb_controller`
*   **AWS Service**: IAM Attachment
*   **AWS Resource Name**: None
*   **Why it is created**: Binds LB control policies to its role.
*   **Depends On**: `aws_iam_role.aws_lb_controller`, `aws_iam_policy.aws_load_balancer_controller`
*   **Required By**: `helm_release.aws_load_balancer_controller`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: Yes

---

### Step 56
*   **Terraform Module**: `module.iam`
*   **Terraform Resource**: `aws_iam_role.cluster_autoscaler`
*   **AWS Service**: AWS IAM
*   **AWS Resource Name**: `cloud-foundation-{env}-cluster-autoscaler-role`
*   **Why it is created**: Autoscaler security context identity.
*   **Depends On**: OIDC provider outputs
*   **Required By**: `aws_iam_role_policy_attachment.cluster_autoscaler`, `helm_release.cluster_autoscaler`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 57
*   **Terraform Module**: `module.iam`
*   **Terraform Resource**: `aws_iam_policy.cluster_autoscaler`
*   **AWS Service**: IAM Policy
*   **AWS Resource Name**: `cloud-foundation-{env}-cluster-autoscaler-policy`
*   **Why it is created**: Specific policy detailing ASG query and scaling actions.
*   **Depends On**: None
*   **Required By**: `aws_iam_role_policy_attachment.cluster_autoscaler`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 58
*   **Terraform Module**: `module.iam`
*   **Terraform Resource**: `aws_iam_role_policy_attachment.cluster_autoscaler`
*   **AWS Service**: IAM Attachment
*   **AWS Resource Name**: None
*   **Why it is created**: Binds autoscaler policies to its role.
*   **Depends On**: `aws_iam_role.cluster_autoscaler`, `aws_iam_policy.cluster_autoscaler`
*   **Required By**: `helm_release.cluster_autoscaler`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: Yes

---

### Step 59
*   **Terraform Module**: `module.node_groups`
*   **Terraform Resource**: `aws_launch_template.this` (count = 2)
*   **AWS Service**: EC2 Launch Template
*   **AWS Resource Name**: `cloud-foundation-{env}-node-[system/applications]-`
*   **Why it is created**: Defines worker node configuration profiles.
*   **Depends On**: `module.security_groups.app_node_sg_id`, `module.kms.eks_kms_key_arn`
*   **Required By**: `aws_eks_node_group.this`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes (stops nodes)
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: Yes

---

### Step 60
*   **Terraform Module**: `module.node_groups`
*   **Terraform Resource**: `aws_eks_node_group.this` (count = 2)
*   **AWS Service**: EKS Node Group (EC2 Instances under ASG)
*   **AWS Resource Name**: `cloud-foundation-{env}-[system/applications]`
*   **Why it is created**: Worker nodes computing resources.
*   **Depends On**: `aws_eks_cluster.this`, `aws_launch_template.this`, `module.iam.node_group_role_arn`, subnets
*   **Required By**: `aws_eks_addon.coredns` (via depends_on module)
*   **Billing**: **Billable (Incurs hourly EC2 instance compute + EBS storage fees)**
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No (cannot install K8s components if no node hosts are active)
*   **Whether partially created resources remain**: Yes (EC2 scaling groups can be left in pending rollout)

---

### Step 61
*   **Terraform Module**: `module.addons`
*   **Terraform Resource**: `aws_eks_addon.coredns`
*   **AWS Service**: EKS Add-on
*   **AWS Resource Name**: `coredns` (linked to cluster)
*   **Why it is created**: Baseline cluster DNS system.
*   **Depends On**: `aws_eks_cluster.this`, `module.node_groups` (via depends_on)
*   **Required By**: `aws_eks_addon.kube_proxy`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 62
*   **Terraform Module**: `module.addons`
*   **Terraform Resource**: `aws_eks_addon.kube_proxy`
*   **AWS Service**: EKS Add-on
*   **AWS Resource Name**: `kube-proxy`
*   **Why it is created**: Internal pod networking proxy.
*   **Depends On**: `aws_eks_cluster.this`, `aws_eks_addon.coredns`
*   **Required By**: `aws_eks_addon.vpc_cni`
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 63
*   **Terraform Module**: `module.addons`
*   **Terraform Resource**: `aws_eks_addon.vpc_cni`
*   **AWS Service**: EKS Add-on
*   **AWS Resource Name**: `vpc-cni`
*   **Why it is created**: Pod interface routing engine.
*   **Depends On**: `aws_eks_cluster.this`, `aws_eks_addon.kube_proxy`
*   **Required By**: `aws_eks_addon.ebs_csi` (via module depends_on)
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: No

---

### Step 64
*   **Terraform Module**: `module.ebs_csi`
*   **Terraform Resource**: `aws_eks_addon.ebs_csi`
*   **AWS Service**: EKS Add-on
*   **AWS Resource Name**: `aws-ebs-csi-driver`
*   **Why it is created**: Dynamic storage controller.
*   **Depends On**: `aws_eks_cluster.this`, `module.iam.ebs_csi_role_arn` (IRSA Role), `module.addons` (via depends_on)
*   **Required By**: `helm_release.metrics_server` (via module depends_on)
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes (stops stateful applications)
*   **Whether Terraform continues after failure**: No (since metrics-server and down-streams rely on stateful controllers)
*   **Whether partially created resources remain**: No

---

### Step 65
*   **Terraform Module**: `module.metrics_server`
*   **Terraform Resource**: `helm_release.metrics_server`
*   **AWS Service**: Helm / K8s Deployment
*   **AWS Resource Name**: `metrics-server` (in `kube-system` namespace)
*   **Why it is created**: Core container monitoring source.
*   **Depends On**: `module.ebs_csi` (via depends_on)
*   **Required By**: `helm_release.aws_load_balancer_controller` (via depends_on)
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes (stops cluster autoscaling metrics loop)
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: Yes (Partially installed Helm charts can be left in K8s state)

---

### Step 66
*   **Terraform Module**: `module.aws_load_balancer_controller`
*   **Terraform Resource**: `helm_release.aws_load_balancer_controller`
*   **AWS Service**: Helm / K8s Deployment
*   **AWS Resource Name**: `aws-load-balancer-controller` (in `kube-system` namespace)
*   **Why it is created**: Manages load balancer resources dynamically.
*   **Depends On**: `module.vpc.vpc_id`, `module.iam.aws_lb_controller_role_arn`, `module.metrics_server` (via depends_on)
*   **Required By**: `helm_release.cluster_autoscaler` (via depends_on)
*   **Billing**: Free
*   **Whether failure here stops the deployment**: Yes (stops ingress routing)
*   **Whether Terraform continues after failure**: No
*   **Whether partially created resources remain**: Yes

---

### Step 67
*   **Terraform Module**: `module.cluster_autoscaler`
*   **Terraform Resource**: `helm_release.cluster_autoscaler`
*   **AWS Service**: Helm / K8s Deployment
*   **AWS Resource Name**: `cluster-autoscaler` (in `kube-system` namespace)
*   **Why it is created**: Scales worker nodes dynamically.
*   **Depends On**: `module.iam.cluster_autoscaler_role_arn`, `module.aws_load_balancer_controller` (via depends_on)
*   **Required By**: None (Final Resource)
*   **Billing**: Free
*   **Whether failure here stops the deployment**: No (last step)
*   **Whether Terraform continues after failure**: Yes (complete)
*   **Whether partially created resources remain**: Yes

---

## 3. ADD-ON DEPENDENCY EXPLANATIONS

The EKS add-ons and Helm charts are deployed in a specific, sequential order because:

1.  **Node Readiness constraint**:
    *   **CoreDNS** must wait for the EKS Managed Node Groups (`aws_eks_node_group.this`) to be fully running. CoreDNS is deployed as pods within the Kubernetes cluster, so it requires active worker nodes with sufficient capacity to schedule and run these DNS pods.
2.  **Add-on Chain sequence**:
    *   **kube-proxy** and **vpc-cni** are chained sequentially after CoreDNS. In any EKS cluster, DNS resolution, IP management, and proxy routing must be stabilized in a linear sequence to prevent race conditions during K8s internal container namespace setup.
    *   **EBS CSI Driver** relies on the OIDC-federated IRSA IAM role (`aws_iam_role.ebs_csi`) for AWS permissions to mount disks. Additionally, it depends on the VPC CNI networking layer being active to communicate with the AWS EC2 storage APIs privately.
3.  **Helm & Metrics constraints**:
    *   **Metrics Server** relies on the EBS CSI storage driver to support stateful local metrics buffers if required, and it requires the core cluster network (DNS, CNI) to collect usage statistics from kubelets.
    *   **AWS Load Balancer Controller** must wait for Metrics Server to ensure the API service registration is active, and it requires the IRSA role (`aws_iam_role.aws_lb_controller`) to configure external target groups in the VPC.
    *   **Cluster Autoscaler** must deploy last because it requires both the AWS Load Balancer controller (to check scaling metrics on ALBs) and its own IRSA scaling role (`aws_iam_role.cluster_autoscaler`) to invoke EC2 scaling modifications.

---

## 4. COMPLETE DEPENDENCY TREE (TEXT REPRESENTATION)

```text
VPC (aws_vpc.main)
 ├── Default Security Group (aws_default_security_group.default)
 ├── Internet Gateway (aws_internet_gateway.igw)
 │     ├── Elastic IP (aws_eip.nat)
 │     │     └── NAT Gateway (aws_nat_gateway.nat)
 │     │           └── Private Route Table (aws_route_table.private)
 │     │                 ├── Private Route Table Association
 │     │                 └── S3 Gateway Endpoint Route Table Association
 │     └── Public Route Table (aws_route_table.public)
 │           ├── Public Route Table Association
 │           └── S3 Gateway Endpoint Route Table Association
 ├── Public Subnets (aws_subnet.public)
 │     ├── Route Table Association (Public)
 │     └── NAT Gateway
 ├── Private Subnets (aws_subnet.private)
 │     ├── Route Table Association (Private)
 │     ├── VPC Interface Endpoints (aws_vpc_endpoint.interface)
 │     └── EKS Managed Node Groups (aws_eks_node_group.this)
 ├── Database Subnets (aws_subnet.database)
 │     ├── Route Table Association (Database)
 │     ├── DB Subnet Group (aws_db_subnet_group.database)
 │     └── Database Network ACL (aws_network_acl.database)
 ├── Route Table (Database) (aws_route_table.database)
 │     ├── Route Table Association (Database)
 │     └── S3 Gateway Endpoint Route Table Association
 ├── Network ACL (Public) (aws_network_acl.public)
 ├── Network ACL (Private) (aws_network_acl.private)
 ├── S3 Gateway Endpoint (aws_vpc_endpoint.s3)
 │     └── S3 Route Table Associations
 ├── VPC Endpoints Security Group (aws_security_group.vpc_endpoints)
 │     └── VPC Interface Endpoints
 ├── VPC Flow Logs Log Group (aws_cloudwatch_log_group.vpc_flow_logs)
 │     └── VPC Flow Logs (aws_flow_log.main)
 ├── VPC Flow Logs IAM Role (aws_iam_role.vpc_flow_log_role)
 │     ├── VPC Flow Logs IAM Policy (aws_iam_role_policy.vpc_flow_log_policy)
 │     └── VPC Flow Logs (aws_flow_log.main)
 ├── Security Groups Module
 │     ├── ALB Security Group (aws_security_group.alb_sg)
 │     │     └── App Node Security Group (aws_security_group.app_node_sg)
 │     │           ├── Database Security Group (aws_security_group.db_sg)
 │     │           ├── EKS Cluster Security Group (aws_security_group.eks_cluster_sg)
 │     │           │     └── EKS Cluster (aws_eks_cluster.this)
 │     │           └── EKS Launch Templates (aws_launch_template.this)
 │     │                 └── EKS Managed Node Groups
 │     └── SSM Bastion Security Group (aws_security_group.ssm_bastion_sg)
 │           └── Database Security Group (aws_security_group.db_sg)
 ├── KMS Keys Module
 │     ├── EKS KMS Key (aws_kms_key.eks)
 │     │     ├── EKS KMS Alias (aws_kms_alias.eks)
 │     │     ├── EKS Cluster (aws_eks_cluster.this)
 │     │     └── EKS Launch Templates (aws_launch_template.this)
 │     ├── CloudWatch KMS Key (aws_kms_key.cloudwatch)
 │     │     ├── CloudWatch KMS Alias (aws_kms_alias.cloudwatch)
 │     │     └── CloudWatch EKS Log Group (aws_cloudwatch_log_group.eks)
 │     │           └── EKS Cluster (aws_eks_cluster.this)
 │     └── ECR KMS Key (aws_kms_key.ecr)
 │           ├── ECR KMS Alias (aws_kms_alias.ecr)
 │           └── ECR Repositories (aws_ecr_repository.this)
 ├── IAM Roles Module
 │     ├── EKS Cluster Role (aws_iam_role.eks_cluster)
 │     │     ├── Role Attachments
 │     │     └── EKS Cluster (aws_eks_cluster.this)
 │     ├── Node Group Role (aws_iam_role.node_group)
 │     │     ├── Role Attachments
 │     │     └── EKS Managed Node Groups (aws_eks_node_group.this)
 │     ├── OIDC Dependent Roles (Constructed post-OIDC Provider instantiation)
 │     │     ├── EBS CSI Role (aws_iam_role.ebs_csi)
 │     │     │     ├── Role Attachments
 │     │     │     └── EBS CSI Add-on (aws_eks_addon.ebs_csi)
 │     │     ├── AWS LB Controller Role (aws_iam_role.aws_lb_controller)
 │     │     │     ├── Role Attachments (includes custom policy)
 │     │     │     └── AWS LB Controller Helm Release
 │     │     └── Cluster Autoscaler Role (aws_iam_role.cluster_autoscaler)
 │     │           ├── Role Attachments (includes custom policy)
 │     │           └── Cluster Autoscaler Helm Release
 └── EKS Control Plane Module
       ├── EKS Cluster (aws_eks_cluster.this)
       │     ├── OIDC Provider (aws_iam_openid_connect_provider.this)
       │     └── EKS Managed Node Groups (aws_eks_node_group.this)
       │           ├── CoreDNS Add-on (aws_eks_addon.coredns)
       │           │     └── kube-proxy Add-on (aws_eks_addon.kube_proxy)
       │           │           └── VPC CNI Add-on (aws_eks_addon.vpc_cni)
       │           │                 └── EBS CSI Driver Add-on (aws_eks_addon.ebs_csi)
       │           │                       └── Metrics Server Helm Release
       │           │                             └── AWS LB Controller Helm Release
       │           │                                   └── Cluster Autoscaler Helm Release
       └── Access Entries / Policy Associations (Empty by default)
```

---

## 5. RECOVERY, TRANSACTION, & BILLING METRICS

### 5.1 At which step does Terraform stop if a resource fails?
If a resource creation fails, Terraform immediately halts execution **for all downstream resources that depend on the failed resource**. Unrelated, independent branches of the dependency tree (e.g., creating ECR repositories while VPC endpoint creation fails) will continue to deploy until they hit a dependency boundary.
*   *VPC Failure (Step 7)*: Execution halts immediately for the entire project.
*   *KMS EKS Key Failure (Step 1)*: VPC and ECR repos deploy, but EKS Cluster, Launch Templates, Node Groups, and all Helm releases halt.
*   *EKS Cluster Failure (Step 49)*: VPC, IAM, SGs, KMS, and ECR successfully deploy, but OIDC Provider, IRSA roles, Node Groups, Add-ons, and Helm releases halt.
*   *Node Group Failure (Step 60)*: Control plane (EKS, OIDC, ECR, VPC) is successfully provisioned, but Add-ons and Helm releases halt.

### 5.2 Which resources remain created after a failure?
Any resource that was successfully created before the failure occurred **remains created in AWS** and is saved in the state file. Terraform does not rollback changes.

### 5.3 Which resources are rolled back automatically?
**None.** Terraform does not support automatic transactional rollbacks. If a resource fails, the infrastructure is left in a partially deployed state. AWS CloudFormation does rollbacks, but Terraform operates purely on state delta execution.

### 5.4 Which resources require manual cleanup?
*   If the apply process is aborted or interrupted (e.g., terminal closed, network lost, Ctrl+C) *during* creation of resources using a `name_prefix` (such as `aws_launch_template.this` or `aws_security_group.app_node_sg` if it were modified), or UUID resources (such as `aws_kms_key.eks`), the resource will be created in AWS but **not written to the state file**. These will remain as orphaned duplicates in AWS and must be cleaned up manually in the AWS Console or imported via `terraform import`.
*   If EKS Node Groups fail to scale down or fail to terminate cleanly due to pod drain blocks, they will hang in `DELETING` state. This requires manual target termination in the AWS EC2 Auto Scaling Console.

### 5.5 Which resources incur AWS charges immediately after creation?
The following resources incur hourly charges as soon as they reach `ACTIVE`/`RUNNING` status in AWS, even if the rest of the deployment fails:
1.  **KMS Customer Managed Keys**: Incurs a flat **$1.00/month** per key (EKS, CW Logs, ECR keys = $3.00/month total).
2.  **NAT Gateways**: Incurs **~$0.045/hour** per gateway.
3.  **VPC Interface Endpoints**: Incurs **~$0.012/hour** per AZ mapping.
4.  **EKS Control Plane**: Incurs **$0.10/hour**.
5.  **EC2 Instances (Node Groups)**: Incur hourly compute fees based on instance sizes (e.g. `t3.medium`, `t3.large`, `m6i.large`).
6.  **EBS gp3 Storage**: Incurs **~$0.08/GB/month** for each worker disk created.
7.  **CloudWatch Logs Ingestion**: Incur ingestion charges (~$0.50/GB) as soon as EKS or Flow logs start streaming data.

### 5.6 Estimated total number of AWS resources created
*   **DEV**: **105 resources**
*   **STAGE**: **105 resources**
*   **PROD**: **113 resources** (contains 2 additional EIPs, 2 additional NAT Gateways, 2 additional Private Route Tables, and 2 additional S3 Endpoint route associations due to Multi-AZ architecture).

---

## 6. DEPLOYMENT TIMELINE

```text
Step 1  → EKS Secrets KMS Key (aws_kms_key.eks)
Step 2  → CW Logs KMS Key (aws_kms_key.cloudwatch)
Step 3  → ECR Storage KMS Key (aws_kms_key.ecr)
Step 4  → EKS KMS Alias (aws_kms_alias.eks)
Step 5  → CW Logs KMS Alias (aws_kms_alias.cloudwatch)
Step 6  → ECR KMS Alias (aws_kms_alias.ecr)
Step 7  → VPC (aws_vpc.main)
Step 8  → Default Security Group (aws_default_security_group.default)
Step 9  → Internet Gateway (aws_internet_gateway.igw)
Step 10 → Public Subnets (aws_subnet.public)
Step 11 → Private App Subnets (aws_subnet.private)
Step 12 → Private DB Subnets (aws_subnet.database)
Step 13 → DB Subnet Group (aws_db_subnet_group.database)
Step 14 → NAT Gateway Elastic IP (aws_eip.nat)
Step 15 → NAT Gateway (aws_nat_gateway.nat)
Step 16 → Route Table Public (aws_route_table.public)
Step 17 → Route Table Private (aws_route_table.private)
Step 18 → Route Table Database (aws_route_table.database)
Step 19 → Route Association Public (aws_route_table_association.public)
Step 20 → Route Association Private (aws_route_table_association.private)
Step 21 → Route Association Database (aws_route_table_association.database)
Step 22 → Public NACL (aws_network_acl.public)
Step 23 → Private NACL (aws_network_acl.private)
Step 24 → Database NACL (aws_network_acl.database)
Step 25 → VPC Endpoints SG (aws_security_group.vpc_endpoints)
Step 26 → S3 Gateway Endpoint (aws_vpc_endpoint.s3)
Step 27 → S3 Endpoint Route Association (aws_vpc_endpoint_route_table_association.s3)
Step 28 → Interface VPC Endpoints (aws_vpc_endpoint.interface)
Step 29 → Flow Logs CW Log Group (aws_cloudwatch_log_group.vpc_flow_logs)
Step 30 → Flow Logs IAM Role (aws_iam_role.vpc_flow_log_role)
Step 31 → Flow Logs IAM Policy (aws_iam_role_policy.vpc_flow_log_policy)
Step 32 → VPC Flow Logs (aws_flow_log.main)
Step 33 → Security Group ALB (aws_security_group.alb_sg)
Step 34 → Security Group App Node (aws_security_group.app_node_sg)
Step 35 → Security Group SSM Bastion (aws_security_group.ssm_bastion_sg)
Step 36 → Security Group RDS Database (aws_security_group.db_sg)
Step 37 → Security Group EKS Cluster (aws_security_group.eks_cluster_sg)
Step 38 → EKS Cluster IAM Role (aws_iam_role.eks_cluster)
Step 39 → Cluster Role Attachment EKS (aws_iam_role_policy_attachment.eks_cluster_policy)
Step 40 → Cluster Role Attachment CNI (aws_iam_role_policy_attachment.eks_vpc_resource_controller)
Step 41 → Node Group IAM Role (aws_iam_role.node_group)
Step 42 → Node Role Attachment Worker (aws_iam_role_policy_attachment.node_worker_policy)
Step 43 → Node Role Attachment CNI (aws_iam_role_policy_attachment.node_cni_policy)
Step 44 → Node Role Attachment ECR (aws_iam_role_policy_attachment.node_ecr_policy)
Step 45 → Node Role Attachment SSM (aws_iam_role_policy_attachment.node_ssm_policy)
Step 46 → EKS CloudWatch Log Group (aws_cloudwatch_log_group.eks)
Step 47 → ECR Repositories (aws_ecr_repository.this)
Step 48 → ECR Lifecycle Policies (aws_ecr_lifecycle_policy.this)
Step 49 → EKS Cluster (aws_eks_cluster.this)
Step 50 → EKS OIDC Provider (aws_iam_openid_connect_provider.this)
Step 51 → EBS CSI IAM Role (aws_iam_role.ebs_csi)
Step 52 → EBS CSI Role Attachment (aws_iam_role_policy_attachment.ebs_csi)
Step 53 → AWS LB Controller IAM Role (aws_iam_role.aws_lb_controller)
Step 54 → AWS LB Controller IAM Policy (aws_iam_policy.aws_load_balancer_controller)
Step 55 → AWS LB Controller Role Attachment (aws_iam_role_policy_attachment.aws_lb_controller)
Step 56 → Cluster Autoscaler IAM Role (aws_iam_role.cluster_autoscaler)
Step 57 → Cluster Autoscaler IAM Policy (aws_iam_policy.cluster_autoscaler)
Step 58 → Cluster Autoscaler Role Attachment (aws_iam_role_policy_attachment.cluster_autoscaler)
Step 59 → EC2 Launch Templates (aws_launch_template.this)
Step 60 → EKS Managed Node Groups (aws_eks_node_group.this)
Step 61 → CoreDNS Add-on (aws_eks_addon.coredns)
Step 62 → kube-proxy Add-on (aws_eks_addon.kube_proxy)
Step 63 → VPC CNI Add-on (aws_eks_addon.vpc_cni)
Step 64 → EBS CSI Driver Add-on (aws_eks_addon.ebs_csi)
Step 65 → Metrics Server (helm_release.metrics_server)
Step 66 → AWS Load Balancer Controller (helm_release.aws_load_balancer_controller)
Step 67 → Cluster Autoscaler (helm_release.cluster_autoscaler)
```
