# Terraform Tagging Audit & Environment Variable Analysis Report

This report provides a systematic audit and compliance analysis of tagging conventions and environment variable utilization across the EKS Platform Terraform codebase.

---

## 1. GLOBAL TAG ANALYSIS

The project utilizes local helpers, module inputs, and provider configurations to apply metadata tags:

### 1.1 Root Environment Declarations (locals)
*   **File Name**: `env/dev/main.tf` (also present in `env/stage/main.tf` and `env/prod/main.tf`)
*   **Line Numbers**: 4 - 16
*   **Complete Tag Object**:
    ```hcl
    locals {
      tags = {
        Project            = var.project_name
        Environment        = var.environment
        Application        = var.application
        Owner              = var.owner
        ManagedBy          = "Terraform"
        CostCenter         = var.cost_center
        Compliance         = var.compliance
        DataClassification = var.data_classification
        Backup             = var.backup
      }
    }
    ```

### 1.2 Provider Default Tags
*   **File Name**: `env/dev/provider.tf` (also in `env/stage/provider.tf` and `env/prod/provider.tf`)
*   **Line Numbers**: 22 - 28
*   **Complete Tag Object**:
    ```hcl
    default_tags {
      tags = {
        Project     = var.project_name
        Environment = var.environment
        ManagedBy   = "Terraform"
      }
    }
    ```

### 1.3 VPC Module Locals (`base_tags`)
*   **File Name**: `modules/vpc/main.tf`
*   **Line Numbers**: 8 - 18
*   **Complete Tag Object**:
    ```hcl
    locals {
      base_tags = {
        Project            = var.project_name
        Environment        = var.environment
        Application        = var.application
        Owner              = var.owner
        ManagedBy          = "Terraform"
        CostCenter         = var.cost_center
        Compliance         = var.compliance
        DataClassification = var.data_classification
        Backup             = var.backup
      }
    }
    ```

### 1.4 Security Groups Module Locals (`base_tags`)
*   **File Name**: `modules/security-groups/main.tf`
*   **Line Numbers**: 2 - 12
*   **Complete Tag Object**: Matches the VPC module's `base_tags` structure, derived from the module variables.

---

## 2. RESOURCE TAG AUDIT

The table below lists all active AWS resources deployed by this project, whether they receive tags, and their configuration source:

| Resource Type | Resource Name | Tags Applied? | Tagging Source / Code Snippet |
| :--- | :--- | :---: | :--- |
| `aws_vpc` | `main` | Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-vpc" })` |
| `aws_subnet` | `public` | Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-subnet-public-${each.value.az}", ... })` |
| `aws_subnet` | `private` | Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-subnet-private-app-${each.value.az}", ... })` |
| `aws_subnet` | `database` | Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-subnet-database-${each.value.az}" })` |
| `aws_internet_gateway`| `igw` | Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-igw" })` |
| `aws_eip` | `nat` | Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-nat-eip-${each.key}" })` |
| `aws_nat_gateway` | `nat` | Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-nat-gw-${each.key}" })` |
| `aws_route_table` | `public` | Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-rt-public" })` |
| `aws_route_table` | `private` | Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-rt-private-${each.key}" })` |
| `aws_route_table` | `database` | Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-rt-database" })` |
| `aws_network_acl` | `public` | Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-nacl-public" })` |
| `aws_network_acl` | `private` | Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-nacl-private" })` |
| `aws_network_acl` | `database` | Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-nacl-database" })` |
| `aws_security_group` | `alb_sg` | Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-alb-sg" })` |
| `aws_security_group` | `app_node_sg` | Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-app-node-sg" })` |
| `aws_security_group` | `ssm_bastion_sg`| Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-ssm-bastion-sg" })` |
| `aws_security_group` | `db_sg` | Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-db-sg" })` |
| `aws_security_group` | `eks_cluster_sg`| Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-eks-cluster-sg" })` |
| `aws_security_group` | `vpc_endpoints` | Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-vpc-endpoints-sg" })` |
| `aws_vpc_endpoint` | `s3` | Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-vpce-s3" })` |
| `aws_vpc_endpoint` | `interface` | Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-vpce-${each.key}" })` |
| `aws_cloudwatch_log` | `vpc_flow_logs` | Yes | `tags = local.base_tags` |
| `aws_iam_role` | `vpc_flow_log_role`| Yes | `tags = local.base_tags` |
| `aws_flow_log` | `main` | Yes | `tags = local.base_tags` |
| `aws_kms_key` | `eks` | Yes | `tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-kms-eks" })` |
| `aws_kms_key` | `cloudwatch` | Yes | `tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-kms-cloudwatch" })` |
| `aws_kms_key` | `ecr` | Yes | `tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-kms-ecr" })` |
| `aws_ecr_repository` | `this` | Yes | `tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-${each.key}" })` |
| `aws_iam_role` | `eks_cluster` | Yes | `tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-eks-cluster-role" })` |
| `aws_iam_role` | `node_group` | Yes | `tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-eks-node-role" })` |
| `aws_iam_role` | `ebs_csi` | Yes | `tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-ebs-csi-role" })` |
| `aws_iam_role` | `aws_lb_controller`| Yes | `tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-aws-lb-controller-role" })` |
| `aws_iam_role` | `cluster_autoscaler`| Yes | `tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-cluster-autoscaler-role" })` |
| `aws_iam_policy` | `aws_lb_controller`| Yes | `tags = var.tags` |
| `aws_iam_policy` | `cluster_autoscaler`| Yes | `tags = var.tags` |
| `aws_iam_openid` | `this` | Yes | `tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-eks-oidc-provider" })` |
| `aws_cloudwatch_log` | `eks` | Yes | `tags = var.tags` |
| `aws_eks_cluster` | `this` | Yes | `tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-eks" })` |
| `aws_launch_template`| `this` | Yes | `tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-launch-template-${var.name}" })` |
| `aws_eks_node_group` | `this` | Yes | `tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-${each.key}" })` |
| `aws_eks_addon` | `coredns` | Yes | `tags = var.tags` |
| `aws_eks_addon` | `kube_proxy` | Yes | `tags = var.tags` |
| `aws_eks_addon` | `vpc_cni` | Yes | `tags = var.tags` |
| `aws_eks_addon` | `ebs_csi` | Yes | `tags = var.tags` |
| `aws_db_subnet_group`| `database` | Yes | `tags = merge(local.base_tags, { Name = "${var.project_name}-${var.environment}-db-subnet-group" })` |

---

## 3. ENVIRONMENT COMPARISON

The metadata tags are evaluated across the three isolated execution states (`dev`, `stage`, `prod`):

| Tag Key | DEV Value | STAGE Value | PROD Value | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Project** | `"cloud-foundation"` | `"cloud-foundation"` | `"cloud-foundation"` | Constant |
| **Environment** | `"dev"` | `"stage"` | `"prod"` | **Changes Dynamically** |
| **Application** | `"Infrastructure"` | `"Infrastructure"` | `"Infrastructure"` | Constant |
| **Owner** | `"Platform-Team"` | `"Platform-Team"` | `"Platform-Team"` | Constant |
| **ManagedBy** | `"Terraform"` | `"Terraform"` | `"Terraform"` | Constant |
| **CostCenter** | `"Engineering"` | `"Engineering"` | `"Engineering"` | Constant |
| **Compliance** | `"HIPAA"` | `"HIPAA"` | `"HIPAA"` | Constant |
| **Backup** | `"Enabled"` | `"Enabled"` | `"Enabled"` | Constant |
| **DataClassification**| `"Confidential"` | `"Confidential"` | `"Confidential"` | Constant |
| **Name** | `cloud-foundation-dev-[res]`| `cloud-foundation-stage-[res]`| `cloud-foundation-prod-[res]`| **Changes Dynamically** |

*Analysis*: The metadata matches parameters perfectly. The `Environment` and `Name` tags scale dynamically based on environment. There are no static tag collisions.

---

## 4. TAG VARIABLE RESOLUTION

Every tag applied to AWS resources resolves along the following dependency chains:

### Chain 1: EKS Cluster Resource Tag Resolution
```text
aws_eks_cluster.this (tags)
  └── merge(var.tags, { Name = "cloud-foundation-{env}-eks" })
        └── env/*/main.tf: module "eks" (tags = local.tags)
              └── env/*/main.tf: local.tags (maps variables)
                    └── env/*/variables.tf (defines default values)
```

### Chain 2: VPC Networking Resource Tag Resolution
```text
aws_vpc.main (tags)
  └── merge(local.base_tags, { Name = "cloud-foundation-{env}-vpc" })
        └── modules/vpc/main.tf: local.base_tags (maps module variables)
              └── env/*/main.tf: module "vpc" (assigns variables from var.*)
                    └── env/*/variables.tf (defines default values)
```

---

## 5. PROVIDER DEFAULT TAGS

The `aws` provider configures baseline default tags:
```hcl
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
```
*   **Inheritance**: All taggable AWS resources deployed in the environment folder automatically inherit these three default tags (`Project`, `Environment`, `ManagedBy`) at the provider level, ensuring tag compliance even if a resource lacks an explicit `tags =` configuration block.

---

## 6. HARDCODED TAGS

We checked the active codebase for static, hardcoded tags:
*   **Active Configurations**: **None**. There are no static hardcoded tags in the active modules or environment folders. All metadata tags are computed dynamically using local variables and module inputs.
*   **Scaffolded / Inactive Configurations**: Hardcoded tags are present in inactive placeholder files:
    *   `modules/ecs/iam.tf` (lines 18, 51): `tags = { Environment = "Dev", Project = "ECS-HIPAA" }`
    *   `modules/codedeploy/main.tf` (lines 14, 30, 43): `tags = { Environment = "Dev", Project = "ECS-HIPAA" }`
    *   `modules/ecs/autoscaling.tf` (line 7): `tags = { Environment = "Dev" }`
*   **Risk Analysis**: Because these scaffolded modules are completely inactive and not instantiated by the environment main files, they present **no risk** of configuration drift or collision during deployment.

---

## 7. ENVIRONMENT VARIABLE USAGE (`var.environment`)

The `var.environment` parameter acts as the primary prefix namespaces across all environments:

### Traced Occurrences of `var.environment`:
1.  **VPC Module**: Sets resource tags and names:
    *   `Name = "${var.project_name}-${var.environment}-vpc"`
2.  **ECR Module**: Sets repo prefixes:
    *   `Name = "${var.project_name}-${var.environment}-${each.key}"`
3.  **KMS Module**: Configures key tags and aliases:
    *   `target_key_id = ...` and alias: `alias/${var.project_name}-${var.environment}-[service]`
4.  **IAM Module**: Names execution roles:
    *   `name = "${var.project_name}-${var.environment}-eks-cluster-role"`
5.  **CloudWatch Logs**: Names log groups:
    *   `name = "/aws/eks/${var.project_name}-${var.environment}-eks/cluster"`
6.  **Security Groups**: Scopes SGs:
    *   `name = "${var.project_name}-${var.environment}-alb-sg"`
7.  **Launch Templates & Node Groups**: Scopes groups:
    *   `Name = "${var.project_name}-${var.environment}-launch-template-${var.name}"`
    *   `node_group_name = "${var.project_name}-${var.environment}-${each.key}"`
8.  **EKS Cluster**: Names the EKS cluster:
    *   `cluster_name = "${var.project_name}-${var.environment}-eks"`

*Conclusion*: Changing `var.environment` dynamically scales all resource namespaces, tags, ECR paths, security groups, KMS aliases, and cluster names. Nothing remains hardcoded.

---

## 8. NAMING CONVENTION AUDIT

The table below lists the final generated AWS Console names for core resources across the three environments:

| Resource Type | DEV Name | STAGE Name | PROD Name |
| :--- | :--- | :--- | :--- |
| `aws_vpc` | `cloud-foundation-dev-vpc` | `cloud-foundation-stage-vpc` | `cloud-foundation-prod-vpc` |
| `aws_internet_gateway`| `cloud-foundation-dev-igw` | `cloud-foundation-stage-igw` | `cloud-foundation-prod-igw` |
| `aws_nat_gateway` | `cloud-foundation-dev-nat-gw-ap-south-1a`| `cloud-foundation-dev-nat-gw-ap-south-1a`| `cloud-foundation-prod-nat-gw-ap-south-1[a/b/c]`|
| `aws_route_table` (Pub) | `cloud-foundation-dev-rt-public` | `cloud-foundation-stage-rt-public` | `cloud-foundation-prod-rt-public` |
| `aws_security_group` | `cloud-foundation-dev-app-node-sg`| `cloud-foundation-stage-app-node-sg`| `cloud-foundation-prod-app-node-sg`|
| `aws_kms_key` (EKS) | Key Alias: `cloud-foundation-dev-eks`| Key Alias: `cloud-foundation-stage-eks`| Key Alias: `cloud-foundation-prod-eks`|
| `aws_eks_cluster` | `cloud-foundation-dev-eks` | `cloud-foundation-stage-eks` | `cloud-foundation-prod-eks` |
| `aws_eks_node_group` | `cloud-foundation-dev-system` | `cloud-foundation-stage-system` | `cloud-foundation-prod-system` |
| `aws_ecr_repository` | `cloud-foundation-dev-authlogin` | `cloud-foundation-stage-authlogin` | `cloud-foundation-prod-authlogin` |
| `aws_db_subnet_group`| `cloud-foundation-dev-db-subnet-group`| `cloud-foundation-stage-db-subnet-group`| `cloud-foundation-prod-db-subnet-group`|

---

## 9. MISSING TAGS

Certain resources do not receive tags. The table below lists these resources and why:

| Resource Type | Resource Name | Reason for No Tags | Expected Action |
| :--- | :--- | :--- | :--- |
| `aws_route_table_association`| `public`, `private`, `database`| Not supported by AWS EC2 route association API. | None (API constraint). |
| `aws_vpc_endpoint_route_table_association`| `s3` | Not supported by AWS EC2 endpoint association API. | None (API constraint). |
| `aws_iam_role_policy_attachment`| EKS/Node policy attachments | Not supported by AWS IAM policy attachment API. | None (API constraint). |
| `aws_iam_role_policy` | `vpc_flow_log_policy` (inline) | Not supported by AWS IAM inline policy API. | None (API constraint). |
| `aws_kms_alias` | KMS aliases | Not supported by AWS KMS Alias API (only Key can be tagged). | None (API constraint). |
| `helm_release` | Metrics Server / LBC / Autoscaler| Helm releases are Kubernetes-internal resources; no AWS tags apply. | None. |

---

## 10. FINAL SUMMARY

1.  **Tag Definitions**: Tags are defined in the environment variables, compiled in the environment locals (`local.tags`), and passed down as variables to the ECR, KMS, IAM, EKS, Node Group, and CloudWatch modules. The VPC and Security Group modules compile tags using their own variables.
2.  **Environment Variations**: Only the `Environment` metadata tag and the `Name` tag change dynamically based on `var.environment` (scaling to `dev`, `stage`, or `prod`).
3.  **Constant Tags**: `Project`, `Application`, `Owner`, `ManagedBy`, `CostCenter`, `Compliance`, `DataClassification`, and `Backup` are constant values.
4.  **Multi-Environment Safety**: **Yes, the project is completely safe for multi-environment deployment.** Resource namespaces, logs, ECR prefixes, KMS keys, security groups, and route tables scale cleanly with the environment name. There are no active static tags or naming conflicts.
