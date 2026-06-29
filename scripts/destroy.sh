#!/bin/bash
set -e

echo "Destroying dev environment..."
cd ../env/dev

terraform destroy -auto-approve
