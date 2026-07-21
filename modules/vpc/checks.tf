# ------------------------------------------------------------------------------
# VPC Subnet Allocation Validation Checks
# ------------------------------------------------------------------------------

check "subnet_alignment" {
  assert {
    condition     = length(var.private_subnet_cidrs) == length(var.public_subnet_cidrs)
    error_message = "VPC Configuration Error: The number of private application subnets (${length(var.private_subnet_cidrs)}) must match the number of public subnets (${length(var.public_subnet_cidrs)}) to ensure uniform Availability Zone mapping."
  }

  assert {
    condition     = !var.enable_database_networking || length(var.database_subnet_cidrs) == length(var.public_subnet_cidrs)
    error_message = "VPC Configuration Error: The number of private database subnets (${length(var.database_subnet_cidrs)}) must match the number of public subnets (${length(var.public_subnet_cidrs)}) to ensure uniform Availability Zone mapping."
  }
}
