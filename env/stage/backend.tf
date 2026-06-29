terraform {
  backend "s3" {
    bucket         = "terraform-aws-enterprise-state"
    key            = "stage/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
