#!/bin/bash

# This script dynamically initializes the Terraform backend by fetching resource names from the 'foundation' module

set -e

echo "Fetching backend configuration from 'foundation' outputs..."

BUCKET_NAME=$(terraform -chdir=./foundation output -raw s3_bucket_name)
TABLE_NAME=$(terraform -chdir=./foundation output -raw dynamodb_table_name)

echo "Backend S3 Bucket: $BUCKET_NAME"
echo "Backend DynamoDB Table: $TABLE_NAME"

echo "Initializing Terraform for the main project..."

terraform init -reconfigure \
    -backend-config="bucket=$BUCKET_NAME" \
    -backend-config="key=csv2json/terraform.tfstate" \
    -backend-config="region=eu-central-1" \
    -backend-config="dynamodb_table=$TABLE_NAME"

echo ""
echo "Terraform initialization complete."