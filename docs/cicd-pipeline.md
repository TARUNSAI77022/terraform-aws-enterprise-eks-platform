# Enterprise CI/CD Pipeline Architecture & Governance

This document describes the design, security controls, and promotion model of the GitHub Actions CI/CD pipeline used to manage the AWS network infrastructure.

---

## 1. Pipeline Workflows Architecture

The repository contains five single-responsibility workflows:

```mermaid
graph TD
    classDef default font-family:Inter, sans-serif;
    classDef validate fill:#E6F6F7,stroke:#00A4A6,stroke-width:1px,color:#007D7E;
    classDef plan fill:#E8F4FD,stroke:#125FB3,stroke-width:1px,color:#0E4A8C;
    classDef apply fill:#F6EEF9,stroke:#9D3FBD,stroke-width:1px,color:#6C1F8C;
    classDef drift fill:#FFF5E6,stroke:#FF9900,stroke-width:1px,color:#CC7A00;

    PR[Pull Request to main] --> ValidateWF["Validate Workflow<br/>(init, fmt, validate, tflint, tfsec, checkov)"]:::validate
    ValidateWF -- Passes --> PlanWF["Plan Workflow<br/>(OIDC, tfplan + txt, Infracost)"]:::plan
    PlanWF -- Artifact Saved --> ManualApproval{GitHub Environment Gate<br/>(dev / stage / prod)}
    ManualApproval -- Approved by Operator --> ApplyWF["Apply Workflow<br/>(OIDC, Apply tfplan)"]:::apply
    
    CronSchedule((📅 Scheduled Cron)) --> DriftWF["Drift Detection Workflow<br/>(weekly check)"]:::drift
```

### 1. Validation Workflow (`terraform-validate.yml`)
- **Trigger**: Run on pull requests and pushes to `main`.
- **Purpose**: Fail-fast syntax and security auditing.
- **Operations**:
  - Sets up the `.terraform.d/plugin-cache` caching to speed up runs.
  - Initializes the remote backend using `terraform init` to verify backend connectivity.
  - Verifies styling consistency using `terraform fmt` and verifies committed provider locks.
  - Scans configurations using TFLint, tfsec, and Checkov.

### 2. Plan Workflow (`terraform-plan.yml`)
- **Trigger**: Run on pull requests and manual triggers (`workflow_dispatch`).
- **Purpose**: Generates the execution plan and forecasts costs.
- **Operations**:
  - Authenticates dynamically to AWS using OpenID Connect (OIDC).
  - Compiles the plan into a binary `tfplan` file and exports a readable `terraform-plan.txt` log.
  - Computes monthly infrastructure cost projections using Infracost.
  - Uploads plans and cost reports as secure, time-bound GitHub build artifacts.

### 3. Apply Workflow (`terraform-apply.yml`)
- **Trigger**: Manual trigger only.
- **Purpose**: Deploys approved changes.
- **Operations**:
  - Gated using **GitHub Environments** (`dev`, `stage`, `prod`). The `prod` environment enforces a manual approval requirement.
  - Downloads the exact binary `tfplan` from the specified plan run.
  - Applies the plan without regenerating it, ensuring that only the reviewed changes are deployed.

### 4. Drift Detection Workflow (`terraform-drift.yml`)
- **Trigger**: Scheduled weekly cron (Mondays at 08:00 UTC) and manual triggers.
- **Purpose**: Detects changes between actual AWS resources and the state file.
- **Operations**:
  - Runs `terraform plan -detailed-exitcode`.
  - An exit code of `2` indicates that drift has occurred. The workflow writes the differences to the Job Summary, fails the build (to trigger administrative alerts), and uploads a drift report.

### 5. Teardown Workflow (`terraform-destroy.yml`)
- **Trigger**: Manual trigger only.
- **Purpose**: Tears down resources safely.
- **Operations**:
  - Requires entering the confirmation string `YES` and passing through Environment approvals.
  - Generates a destroy plan for operator review before execution.

---

## 2. AWS OIDC Authentication Setup

Long-lived credentials (like `AWS_ACCESS_KEY_ID`) represent a major security risk. We authenticate GitHub Actions using **AWS OpenID Connect (OIDC)**:

### Configuration Steps:
1. **Create Identity Provider in IAM**:
   - Provider URL: `https://token.actions.githubusercontent.com`
   - Audience: `sts.amazonaws.com`
2. **Configure IAM Role Trust Policy**:
   Create the OIDC role named `CloudFoundationGitHubActionsRole` with the following trust policy (replacing `<AWS_ACCOUNT_ID>` with your actual AWS Account ID):
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
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
3. **Configure Secrets**:
   - Save the IAM Role ARN as `AWS_ROLE_ARN` in your GitHub secrets.
   - Ensure `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are removed from your GitHub repository secrets.

---

## 3. Branch Protection & Environment Promotion Model

To secure production environments, the following promotion policy is enforced:

1. **Development (`dev`)**:
   - PR opened -> `validate` and `plan` run automatically.
   - Merged to `main` -> Plan is stored. Operators can deploy to `dev` manually.
2. **Staging (`stage`)**:
   - Changes are planned using manual workflow triggers.
   - Deployments must pass the `stage` Environment approval gate.
3. **Production (`prod`)**:
   - Deployments require approvals from at least two designated SecOps administrators.
   - Pushes to the `main` branch directly are blocked.

### Recommended GitHub Settings:
- Enable **Require pull request reviews before merging** on `main`.
- Enable **Require status checks to pass** before merging (bind to the `Validate Infrastructure` check).
- Configure environments (`dev`, `stage`, `prod`) in your GitHub repository settings and restrict who can approve deployments.

---

## 4. Disaster Recovery & Drift Remediation

### Drift Remediation Steps:
If `terraform-drift.yml` fails and reports drift:
1. Locate the run and download the `drift-report.txt` artifact.
2. **To import manual changes**: If the manual change was approved but bypassed Terraform, update the Terraform code to match the change, commit, and push.
3. **To overwrite manual changes**: Run the `terraform-plan.yml` and `terraform-apply.yml` workflows. This will overwrite manual drift and return resources to the configuration definition.

### State Corruption Recovery:
- S3 bucket versioning is enabled on the remote backend. If the state file gets corrupted, restore the previous working version from S3 using the AWS console.
- DynamoDB state locks can be cleared manually using the CLI if a build crashes and fails to release the lock:
  ```bash
  aws dynamodb delete-item --table-name terraform-state-lock --key '{"LockID": {"S": "dev/terraform.tfstate"}}'
  ```
