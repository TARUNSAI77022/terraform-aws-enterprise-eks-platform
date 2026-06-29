# Enterprise Infrastructure Teardown & Recovery Governance

This document describes the compliance, security controls, and operational workflows for executing resource destruction (teardowns) within the AWS platform infrastructure.

---

## 1. Destroy Pipeline Architecture

To prevent accidental deletions, the teardown process is split into two distinct execution phases:

```mermaid
graph TD
    classDef default font-family:Inter, sans-serif;
    classDef step1 fill:#FFF5E6,stroke:#FF9900,stroke-width:1px,color:#CC7A00;
    classDef step2 fill:#F6EEF9,stroke:#9D3FBD,stroke-width:1px,color:#6C1F8C;

    Trigger[Manual Trigger: Operator] --> ConfirmMatch{Confirmation Matches<br/>Selected Environment?}
    ConfirmMatch -- Yes --> PlanWF["Destroy Plan Workflow<br/>(Health check, state pull, plan -destroy)"]:::step1
    ConfirmMatch -- No --> Fail[Pipeline Aborted]
    
    PlanWF -- Artifact Saved --> Gate{GitHub Environment Gate<br/>(dev / stage / prod)}
    Gate -- Approved by Reviewer --> ApplyWF["Destroy Apply Workflow<br/>(Downloads tfplan-destroy, Apply)"]:::step2
```

---

## 2. Access Controls & Approvals

### Authorization Policy
- **Trigger Rights**: Only senior members of the DevSecOps / Platform engineering team are authorized to trigger destroy workflows.
- **Reviewers Policy**: Staging and Production teardowns must be reviewed and approved by a minimum of two senior infrastructure administrators in the GitHub Environments gate before the Apply phase can begin.

### Environment Confirmation Codes
When triggering the **Destroy Plan** workflow, operators must input the confirmation code that corresponds exactly to their environment:

- **Development (`dev`)**: Input must be exactly `YES`
- **Staging (`stage`)**: Input must be exactly `DESTROY-STAGE`
- **Production (`prod`)**: Input must be exactly `DESTROY-PROD`

If the input code does not match the environment parameter, the validation step fails immediately and halts the pipeline.

---

## 3. Terraform State Protection & Audit Controls

Teardowns are highly risky. To protect state files and ensure traceability:

### State Health & Lock
- **Unreachable Backend Protection**: Prior to running the plan, the workflow runs `terraform state list` to check backend health. If S3 or DynamoDB is down or locked, the check fails and execution halts.
- **Pre-Destroy State Backup**: A state backup reference is captured by running `terraform state pull > state-backup.json` and uploaded as an artifact.
- **DynamoDB State Locking**: Prevents concurrent operations from mutating the state during deletion.

### Artifact Management & Retention
Teardown artifacts (`tfplan-destroy`, `plan-destroy.txt`, and `state-backup.json`) are uploaded and retained in GitHub according to the environment level:
- **Development**: 7 Days
- **Staging**: 14 Days
- **Production**: 30 Days (standard compliance archive duration)

---

## 4. Disaster Recovery (DR) and State Rollbacks

### S3 State Versioning & Rollback
In the event of a corrupt state file or an unauthorized destroy action, you can restore the infrastructure state:
1. Access the Amazon S3 console and navigate to the backend bucket `terraform-aws-enterprise-state`.
2. Enable the **Show versions** switch.
3. Locate the state file (e.g. `stage/terraform.tfstate`).
4. Select the last working version (created prior to the destroy operation) and delete the newer "Delete Marker" or corrupted versions.
5. In your terminal, run `terraform state pull` to verify that the state has successfully rolled back.

### Manual Resource Recovery Post-Destruction
Certain AWS components cannot be recreated via a clean Terraform Apply if their source data is lost:
1. **ECR Repositories**: Docker base images must be rebuilt and pushed to ECR before ECS services can restart.
2. **SSM Parameter Store Secrets**: Sensitive environment values (JWT secrets, MongoDB URIs) must be populated manually or re-generated.
3. **Persistent Backups**: Databases and customer data must be recovered from backups.

### Recovery Objectives (RPO & RTO Assumptions)
For this lab environment:
- **Recovery Point Objective (RPO)**: **24 Hours** (based on standard daily backups of configuration state and parameters).
- **Recovery Time Objective (RTO)**: **2 Hours** (estimated duration to restore S3 state files, re-initialize provider directories, deploy the networking layer, and repopulate container images).
