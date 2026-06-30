# Operational Runbook: Amazon EKS Platform Upgrades

This document outlines the standard operational procedures for executing EKS cluster, node pool, and addon upgrades for the Enterprise Terraform Platform.

---

## 1. Compatibility Matrix

Before upgrading Kubernetes or any platform addons, verify the compatibility matrix. Below is the tested baseline for EKS version **1.30**:

| Platform Component | Pinned Version | EKS v1.29 Compatibility | EKS v1.30 Compatibility | EKS v1.31 Compatibility |
| :--- | :--- | :--- | :--- | :--- |
| **Kubernetes Control Plane** | `1.30` | Supported | **Target Baseline** | Supported |
| **CoreDNS EKS Addon** | `v1.11.1-eksbuild.9` | Compat (v1.10.x) | **Target Baseline** | Compat (v1.11.x) |
| **kube-proxy EKS Addon** | `v1.30.0-eksbuild.3` | Compat (v1.29.x) | **Target Baseline** | Compat (v1.30.x) |
| **VPC CNI EKS Addon** | `v1.18.1-eksbuild.3` | Compatible | **Target Baseline** | Compatible |
| **EBS CSI Driver EKS Addon**| `v1.30.0-eksbuild.1` | Compatible | **Target Baseline** | Compatible |
| **Metrics Server Helm** | `3.12.1` | Compatible | **Target Baseline** | Compatible |
| **AWS Load Balancer Helm** | `1.8.1` | Compatible | **Target Baseline** | Compatible |
| **Cluster Autoscaler Helm** | `9.37.0` | Compatible (v9.35.x)| **Target Baseline** | Compatible (v9.38.x)|

---

## 2. EKS Control Plane Upgrade Procedure

AWS EKS control plane upgrades must be performed one minor version at a time (e.g., `1.29` -> `1.30`). EKS does not support skipping minor versions.

### Pre-upgrade Checks
1. **API Deprecations**: Run `pluto` or `kubent` to detect if any deprecated APIs are in use by workloads in the cluster.
2. **KMS & Logging Health**: Ensure the KMS keys are active and CloudWatch Log groups have sufficient limits.
3. **IAM Permissions**: Verify OIDC roles are valid and configured with appropriate permissions.

### Upgrade Steps
1. **Update Control Plane Version in Terraform**:
   Modify `kubernetes_version` variable in `variables.tf` or `terraform.tfvars`:
   ```hcl
   kubernetes_version = "1.30"
   ```
2. **Execute Terraform Plan**:
   ```bash
   terraform plan -target=module.eks
   ```
3. **Execute Terraform Apply**:
   ```bash
   terraform apply -target=module.eks
   ```
   *Note: This process is non-disruptive to running workloads. The EKS control plane remains highly available during the update (approx. 30-40 minutes).*

---

## 3. Node Group Upgrade Strategy

Once the control plane upgrade completes, worker node groups must be upgraded to match the control plane version.

We use EKS Managed Node Groups with a **Rolling Upgrade Strategy** to ensure zero-downtime migrations.

### Rolling Upgrade Configuration
Each node group has a configurable `update_config` block:
- `max_unavailable` (defaults to `1`): Limits the number of nodes EKS replaces concurrently.
- `max_unavailable_percentage`: Alternative to limit replacement by percentage of the pool.

### Step-by-Step Node Upgrade
1. **Update Node Group AMI/Version in Terraform**:
   Terraform will dynamically update the Launch Template references or EKS Managed Node Group versions.
2. **Apply Changes**:
   ```bash
   terraform apply -target=module.node_groups
   ```
3. **Rolling Update Mechanism**:
   - AWS EKS provisions a new node matching the updated Launch Template / AMI.
   - Once the new node is healthy (`Ready` state), EKS drains one of the old nodes.
   - Pods are evicted and rescheduled on the new node following `PodDisruptionBudgets`.
   - The old node is terminated, and the cycle continues until all nodes are replaced.

---

## 4. Add-on Upgrade Order

Add-ons must be upgraded *after* the control plane is updated. Upgrading them in the correct sequence prevents routing or DNS failures:

1. **kube-proxy**: Upgraded first as it configures network routing.
2. **VPC CNI**: Configures pod-level IP allocation and networking.
3. **CoreDNS**: Restores internal name resolution matching the new version.
4. **EBS CSI Driver**: Ensures storage mounting remains operational.
5. **Helm Releases**: Update AWS Load Balancer Controller, Metrics Server, and Cluster Autoscaler to versions compatible with the new cluster version.

To upgrade in Terraform:
1. Modify the version variables in the environment configuration (e.g. `coredns_version`, `kube_proxy_version`).
2. Run `terraform apply`.

---

## 5. Rollback Guidance

If an upgrade encounters severe issues (e.g. pods fail to reschedule, networking partitions):

### Control Plane
- **AWS EKS Control Planes cannot be downgraded**. Once upgraded, you cannot revert to a previous minor version.
- **Mitigation**: Troubleshoot the control plane issues directly or restore cluster state from backups (scaffolded via `modules/velero`).

### Node Groups
- **Rollback Process**:
  1. Revert the version/AMI variables in your Terraform configuration to the previous working state.
  2. Run `terraform apply`.
  3. EKS will trigger another rolling upgrade, terminating the new nodes and re-provisioning nodes with the previous AMI/settings.

### Addons
- **Rollback Process**:
  1. Downgrade the version variable in your Terraform configuration.
  2. Run `terraform apply`. EKS will downgrade the addon components.
