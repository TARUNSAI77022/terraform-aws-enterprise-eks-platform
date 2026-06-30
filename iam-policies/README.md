# CloudFoundation Enterprise Deployment IAM Policy Package

This directory contains the production-grade, least-privilege IAM policies required to deploy the **cloud-foundation** EKS platform on AWS using Terraform.

These policies avoid the use of wildcard `AdministratorAccess` or `PowerUserAccess` policies, aligning directly with AWS Security Best Practices and the Principle of Least Privilege.

---

## 1. Directory Structure

The files are structured logically by service layer and lifecycle boundary:

```text
iam-policies/
├── README.md                                           # Implementation and deployment guide
├── backend/
│   ├── CloudFoundation-S3Backend-Policy.json          # Terraform State S3 read/write permissions
│   └── CloudFoundation-DynamoDBLock-Policy.json       # DynamoDB lock table state key actions
├── shared/
│   └── CloudFoundation-CommonReadOnly-Policy.json     # Global describes and resource mappings
├── networking/
│   ├── CloudFoundation-VPC-Policy.json               # Subnets, NAT, endpoints, SGs, NACLs
│   ├── CloudFoundation-CloudWatchLogs-Policy.json     # VPC flow logs groups and log streams
│   ├── CloudFoundation-IAM-Policy.json                # Project role creation and PassRole constraints
│   └── CloudFoundation-RDS-Policy.json                # Database subnet groups and RDS instances
├── containers/
│   ├── CloudFoundation-ECR-Policy.json               # ECR repository lifecycle and Docker uploads
│   ├── CloudFoundation-ECS-Policy.json               # Cluster orchestration and task templates
│   ├── CloudFoundation-ALB-Policy.json                # Application Load Balancers and target groups
│   ├── CloudFoundation-CodeDeploy-Policy.json         # Deployment groups and release workflows
│   └── CloudFoundation-AutoScaling-Policy.json        # Launch templates and scaling groups
└── security/
    ├── CloudFoundation-KMS-Policy.json                # Customer Managed Keys (CMK) and aliases
    ├── CloudFoundation-SecretsManager-Policy.json     # Secrets and database credential storage
    └── CloudFoundation-SSM-Policy.json                # Systems Manager Parameter Store parameters
```

---

## 2. Policy Catalog

### Backend Policies (`backend/`)
* **`CloudFoundation-S3Backend-Policy.json`**:
  * **AWS Services**: S3 State Bucket (`terraform-aws-enterprise-state`).
  * **Rationale**: Allows read/write actions on workspace state keys while using an explicit **Deny** statement to prevent bucket deletion.
* **`CloudFoundation-DynamoDBLock-Policy.json`**:
  * **AWS Services**: DynamoDB State Lock Table (`terraform-state-lock`).
  * **Rationale**: Allows locking metadata manipulation (`GetItem`, `PutItem`, `DeleteItem`) while using an explicit **Deny** statement to prevent table deletion.

### Shared Policies (`shared/`)
* **`CloudFoundation-CommonReadOnly-Policy.json`**:
  * **AWS Services**: EC2, ELB, ASG, ECS, ECR, RDS, IAM, CloudWatch Logs, KMS.
  * **Rationale**: Group-level describe and listing permissions that do not support resource-level restrictions. These are required by Terraform to compile resource graphs and detect drift against existing resources during `terraform plan` execution.

### Cloud Foundation (Phase 1) Policies (`networking/` & `security/`)
* **`CloudFoundation-VPC-Policy.json`**:
  * **AWS Services**: VPC, Subnets, Internet Gateways, NAT Gateways, Elastic IPs, Route Tables, Network ACLs, Security Groups, VPC Endpoints, Flow Logs.
  * **Rationale**: Allows managing the primary core network structure inside the `ap-south-1` region. Permissions are scoped to project-owned subnets and endpoints.
* **`CloudFoundation-CloudWatchLogs-Policy.json`**:
  * **AWS Services**: CloudWatch Logs.
  * **Rationale**: Scopes logging actions strictly to the VPC flow logs group namespace `/aws/vpc-flow-logs/cloud-foundation-*`.
* **`CloudFoundation-IAM-Policy.json`**:
  * **AWS Services**: IAM Roles, IAM Policies, PassRole.
  * **Rationale**: Restricts role creation to project-related prefixes `cloud-foundation-*` and `CloudFoundation*`. Restricts `iam:PassRole` execution to project roles and only passes them to approved AWS service principals (`ecs-tasks`, `vpc-flow-logs`, `ec2`, `codedeploy`, `autoscaling`).
* **`CloudFoundation-RDS-Policy.json`**:
  * **AWS Services**: RDS database subnet groups, parameter groups, PostgreSQL instances.
  * **Rationale**: Scopes database infrastructure management strictly to project resources named with the `cloud-foundation-*` prefix.
* **`CloudFoundation-KMS-Policy.json`**:
  * **AWS Services**: KMS Keys, Aliases.
  * **Rationale**: Restricts key management operations using the `aws:ResourceTag/Project` condition matching the `cloud-foundation` tag, preventing modification of global/account keys.
* **`CloudFoundation-SecretsManager-Policy.json`**:
  * **AWS Services**: Secrets Manager.
  * **Rationale**: Scopes secret operations to project credentials (`arn:aws:secretsmanager:ap-south-1:*:secret:cloud-foundation-*`).
* **`CloudFoundation-SSM-Policy.json`**:
  * **AWS Services**: Systems Manager (SSM) Parameter Store.
  * **Rationale**: Scopes parameter actions to the project settings path `/cloud-foundation/*`.

### Container Platform (Phase 2 & 3) Policies (`containers/`)
* **`CloudFoundation-ECR-Policy.json`**:
  * **AWS Services**: Elastic Container Registry.
  * **Rationale**: Allows creating registries with prefix `cloud-foundation-*` and pushing/pulling images.
* **`CloudFoundation-ECS-Policy.json`**:
  * **AWS Services**: Elastic Container Service.
  * **Rationale**: Restricts cluster, task definition, and service orchestration actions to the `cloud-foundation-*` namespace.
* **`CloudFoundation-ALB-Policy.json`**:
  * **AWS Services**: Application Load Balancers, Target Groups, Listeners.
  * **Rationale**: Restricts ALB configuration to load balancers prefixed with `cloud-foundation-*`.
* **`CloudFoundation-CodeDeploy-Policy.json`**:
  * **AWS Services**: AWS CodeDeploy.
  * **Rationale**: Limits deployment group settings to project-related apps.
* **`CloudFoundation-AutoScaling-Policy.json`**:
  * **AWS Services**: EC2 Auto Scaling, Launch Templates.
  * **Rationale**: Restricts auto-scaling group creation to names starting with `cloud-foundation-*`.

---

## 3. OIDC Trust Handshake Configuration

The `CloudFoundationGitHubActionsRole` role assumes permissions without utilizing long-lived access keys by trusting the GitHub Actions Identity Provider (IdP) via OpenID Connect (OIDC).

### Trust Relationship JSON (AssumeRolePolicyDocument)
Create the role with the following policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:TARUNSAI77022/terraform-aws-enterprise-eks-platform:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

---

## 4. Deployment Order

To establish the pipeline permissions cleanly, deploy the IAM resources in this sequence:

1. **Deploy OIDC Provider**: Verify that the GitHub OIDC provider `token.actions.githubusercontent.com` is configured in IAM.
2. **Create Policies**: Create the 14 customer-managed IAM policies using the JSON files in this package.
3. **Deploy Role**: Create the `CloudFoundationGitHubActionsRole` role.
4. **Attach Trust Document**: Configure the Role's Trust Relationship ( OIDC handshake ).
5. **Attach Policies**: Attach the 14 customer-managed policies to the role.

---

## 5. Security & Verification Checklists

### IAM Access Analyzer Checklist
- [x] Verify that no policy uses `Action: "*"` combined with `Resource: "*"`.
- [x] Confirm that `iam:PassRole` has both `PassedToService` constraints and resource ARN prefixes.
- [x] Confirm that S3 and DynamoDB delete actions have safety overrides.
- [x] Verify that all ARN conditions use valid region patterns (`ap-south-1`).

### Terraform Compatibility Checklist
- [x] Confirm `terraform init` retrieves lock state via DynamoDB lock policy permissions.
- [x] Confirm `terraform plan` refreshes resources using describe permissions in the read-only policy.
- [x] Confirm `terraform apply` deploys VPC, subnets, SGs, routing, and logs using the VPC/Logs policies.
- [x] Confirm `terraform destroy` successfully cleans up resource graphs without AccessDenied blocks.
