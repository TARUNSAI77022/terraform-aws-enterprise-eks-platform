# Modules: Karpenter (Scaffolding Placeholder)

This module directory is reserved for Karpenter, a fast, flexible Kubernetes node autoscaler.
- **NodePools**: Configures how Karpenter allocates Spot and On-Demand worker nodes dynamically.
- **EC2NodeClasses**: Defines subnets, security groups, AMIs, and instance profiles used by Karpenter.
- **IAM Policies**: IAM Roles for Service Accounts (IRSA) for Karpenter, plus node profiles.

Karpenter is not deployed in Phase 2; the default Cluster Autoscaler is used. This folder secures the future module layout.
