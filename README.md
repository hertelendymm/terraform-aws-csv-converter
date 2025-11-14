# Serverless CSV to JSON Converter

This project implements a fully automated, serverless, event-driven data processing pipeline on AWS. The entire cloud infrastructure is defined as code using Terraform, making the system reproducible and scalable.

The application converts a CSV file into JSON format instantly upon receiving the user's upload. The frontend provides a clean, drag-and-drop interface and manages the secure transfer and retrieval of data.

Live Demo Here: [link](http://csv2json-hosting-ax4zfwlp.s3-website.eu-central-1.amazonaws.com/).

# Architectural Overview

## Project File Structure
```
.
├── .github/
│   └── workflows/
│       └── deploy.yml            # GitHub Actions CI/CD pipeline
├── frontend/                     # Flutter Web Application Root
│   ├── lib/
│   │   └── main.dart             # Main Flutter UI and logic (clean, drag-and-drop)
│   ├── build/                    # (Generated directory after 'flutter build web')
│   ├── pubspec.yaml
│   └── ... (other Flutter files)
├── src/                          # Backend Lambda Source Code (Zipped by Terraform)
│   ├── api_handler.py            # API Gateway handler (Generates pre-signed URLs, lists files)
│   └── lambda_function.py        # S3 event trigger handler (CSV to JSON conversion logic)
├── terraform/                    # Infrastructure as Code (IaC) Root
│   ├── foundation/               # Stage 1: Creates S3 backend and DynamoDB lock table
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── modules/
│   │   ├── api-gateway-lambda/   # Module for HTTP API Gateway and its handler Lambda
│   │   │   ├── main.tf
│   │   │   └── variables.tf
│   │   ├── frontend-hosting/     # Module for S3 website hosting bucket and public policy
│   │   │   ├── main.tf
│   │   │   └── outputs.tf
│   │   └── s3-lambda-pipeline/   # Module for Source/Destination S3 buckets, Lambda converter, and S3 event config
│   │       ├── main.tf
│   │       └── variables.tf
│   ├── main.tf                   # Root configuration (calls all modules and links outputs)
│   ├── variables.tf              # Global variables (project_name, aws_region)
│   ├── outputs.tf                # Outputs (website_url, api_endpoint_url, bucket names)
│   ├── init.sh                   # Script to initialize Terraform with remote backend config
│   └── deploy_frontend.sh        # Script to build Flutter and sync assets to S3
├── .gitignore
└── README.md                     # Project documentation (Architecture, Deployment steps)
```

## Data Flow

1. Upload: User drops a CSV file onto the Flutter frontend.
2. Auth: The frontend requests a pre-signed PUT URL from the API Gateway.
3. Data Transfer: The frontend uses the pre-signed URL to upload the CSV file directly to the Source S3 Bucket.
4. Conversion: The file creation triggers the csv_converter Lambda.
5. Storage: The Lambda downloads the CSV, converts the data to JSON, and uploads the resulting JSON file to the Destination S3 Bucket.
6. Retrieval: The frontend polls the API for the new JSON file, gets a pre-signed GET URL, and downloads the final JSON data for display.

# Technology Stack

## DevOps & Infrastructure
- Cloud Provider: AWS (Amazon Web Services)
- Infrastructure as Code (IaC): Terraform (Modules are used for clean separation of concerns: s3-lambda-pipeline, api-gateway-lambda, frontend-hosting).
- CI/CD: Custom Bash/AWS CLI script for continuous deployment and synchronizing frontend assets.
- Remote State Management: Terraform state is securely stored and locked using an S3 bucket and DynamoDB table.

## Backend & Core Services
- Backend Code: Python 3.9 (Boto3, CSV, JSON standard libraries).
- Core AWS Services:
    - AWS Lambda: Serverless compute for API handling and CSV conversion.
    - Amazon S3: Used for source, destination, and static website hosting (with secure CORS policies).
    - Amazon API Gateway (HTTP): Public endpoint for managing file transfers and listings.
    - AWS IAM: Granular roles and policies for Lambda execution and S3 access.

## Frontend
- Framework: Flutter (for a consistent web UI).
- Interaction: Drag-and-drop file input (desktop_drop).

# Deployment and Usage

## Prerequisites

- AWS Account configured with appropriate credentials (assumed to be available via environment variables or CLI).
- Terraform CLI (v1.13.1+).
- Flutter SDK and environment setup.
- AWS CLI (v2).

