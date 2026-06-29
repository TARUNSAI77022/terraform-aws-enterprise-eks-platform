# Enterprise Resource Tagging Strategy

This document details the standardized metadata labeling policy applied across all AWS resources within the platform infrastructure. Standardized tagging is a key control for HIPAA audits (proving data classification), cost allocation reporting, and automated backup governance.

## Mandatory Tags Schema

Every resource provisioned by Terraform in this infrastructure must contain the following 10 tagging keys:

| Tag Key | Type | Description / Standard Values | Example | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **Name** | Dynamic | Alphanumeric name of the specific resource instance. | `cloud-foundation-dev-vpc` | Identification |
| **Project** | Static | Unified code identifier for the business product. | `cloud-foundation` | Project grouping |
| **Environment** | Static | Stage environment mapping. Allowed: `dev`, `stage`, `prod`. | `dev` | Scope separation |
| **Application** | Static | Specific backend subsystem name. | `Infrastructure` | Service scoping |
| **Owner** | Static | Department or team responsible for the resource. | `Platform-Team` | Accountability |
| **ManagedBy** | Static | Identifies the management system. | `Terraform` | Drift control |
| **CostCenter** | Static | Billing code identifier. | `Engineering` | Cost reporting |
| **Compliance** | Static | Regulatory compliance standards. | `HIPAA` | Audit verification |
| **DataClassification**| Static | Indicates whether the resource stores/processes PHI or secrets. | `Confidential` | Security auditing |
| **Backup** | Static | Defines the automated backup lifecycle. | `Enabled` | DR validation |

---

## Tag Implementation in Terraform

The tagging strategy is enforced using a two-tier approach:

### 1. Default Tags at the Provider Level
To prevent human error (forgetting to add tags on a new resource), baseline environment metadata tags are automatically applied to every supported resource in the AWS provider definition (`provider.tf`):
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

### 2. Module Local Merge
For resource-specific parameters like the `Name` tag or special Kubernetes configurations (like `kubernetes.io/role/elb`), variables are explicitly merged in local maps and passed down:
```hcl
tags = merge(
  local.base_tags,
  {
    Name = "${var.project_name}-${var.environment}-subnet-public-${data.aws_availability_zones.available.names[count.index]}"
    "kubernetes.io/role/elb" = "1"
  }
)
```
This pattern ensures that all future modules can easily consume these tags without duplicating configuration lines.
