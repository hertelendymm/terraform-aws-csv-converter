#!/bin/bash

set -e

echo "--- Starting Frontend Deployment (Plan B) ---"

echo "Fetching outputs from Terraform..."
API_URL=$(terraform -chdir=./terraform output -raw api_endpoint_url)
BUCKET_NAME=$(terraform -chdir=./terraform output -raw hosting_bucket_id)

if [ -z "$API_URL" ] || [ -z "$BUCKET_NAME" ]; then
    echo "Error: Could not fetch API_URL or BUCKET_NAME from Terraform."
    echo "Please ensure 'terraform apply' has been run successfully."
    exit 1
fi

echo "API Endpoint: $API_URL"
echo "S3 Bucket: $BUCKET_NAME"

echo "Changing to frontend directory..."
cd frontend

echo "Building Flutter web app with API_ENDPOINT_URL..."
flutter build web --release --dart-define=API_ENDPOINT_URL=$API_URL

echo "Flutter build complete."

echo "Syncing build files to S3..."
aws s3 sync build/web s3://$BUCKET_NAME

echo "Sync complete."

cd ..
WEBSITE_URL=$(terraform -chdir=./terraform output -raw website_url)

echo ""
echo "--- Deployment Successful ---"
echo "Your app is now live at: $WEBSITE_URL"