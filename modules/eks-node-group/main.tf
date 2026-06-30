resource "aws_launch_template" "this" {
  # checkov:skip=CKV_AWS_341:EKS nodes require response hop limit of 2 for pods to access IMDSv2 / IAM Roles for Service Accounts (IRSA)
  for_each = var.node_groups

  name_prefix   = "${var.project_name}-${var.environment}-node-${each.key}-"
  description   = "Launch template for EKS Managed Node Group: ${each.key}"
  instance_type = each.value.instance_types[0]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = each.value.disk_size
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.kms_key_arn
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 Enforced
    http_put_response_hop_limit = 2
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.node_security_group_id]
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.project_name}-${var.environment}-node-${each.key}" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { Name = "${var.project_name}-${var.environment}-node-${each.key}-vol" })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = var.cluster_name
  node_group_name = "${var.project_name}-${var.environment}-${each.key}"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  capacity_type   = each.value.capacity_type
  ami_type        = each.value.ami_type
  instance_types  = each.value.instance_types

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  launch_template {
    id      = aws_launch_template.this[each.key].id
    version = aws_launch_template.this[each.key].latest_version
  }

  labels = each.value.labels

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  dynamic "update_config" {
    for_each = each.value.update_config != null ? [each.value.update_config] : []
    content {
      max_unavailable            = lookup(update_config.value, "max_unavailable", null)
      max_unavailable_percentage = lookup(update_config.value, "max_unavailable_percentage", null)
    }
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  tags = merge(
    var.tags,
    {
      Name                                        = "${var.project_name}-${var.environment}-${each.key}"
      "karpenter.sh/discovery"                    = var.cluster_name
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )
}
