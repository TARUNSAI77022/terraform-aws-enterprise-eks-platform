#!/bin/bash
set -e

echo "Deploying dev environment..."
cd ../env/dev

terraform init
terraform plan -out=tfplan
terraform apply "tfplan"
