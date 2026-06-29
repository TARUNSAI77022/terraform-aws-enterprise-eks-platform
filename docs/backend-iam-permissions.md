# Terraform Backend IAM Permissions

To securely manage the Terraform remote state in GitHub Actions, your AWS IAM user/role needs explicit permissions to interact with the S3 bucket and DynamoDB table.

Below is the required JSON IAM Policy. Attach this to the IAM user (`terraform-admin`) or IAM Role that your GitHub Actions workflow assumes:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "TerraformStateBucketAccess",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::terraform-aws-enterprise-state",
                "arn:aws:s3:::terraform-aws-enterprise-state/*"
            ]
        },
        {
            "Sid": "TerraformStateLockingAccess",
            "Effect": "Allow",
            "Action": [
                "dynamodb:DescribeTable",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:DeleteItem"
            ],
            "Resource": "arn:aws:dynamodb:ap-south-1:*:table/terraform-state-lock"
        }
    ]
}
```

### Pre-requisites Before Running the Workflow:
1. Ensure the S3 bucket `terraform-aws-enterprise-state` actually exists in `ap-south-1` and has **Bucket Versioning** enabled.
2. Ensure the DynamoDB table `terraform-state-lock` exists in `ap-south-1` and has a Partition Key named `LockID` (String type).
