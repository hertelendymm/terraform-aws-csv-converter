# Automated CSV to JSON Converter
*This capstone project is a fully automated, serverless, event-driven data processing pipeline on AWS. The entire cloud infrastructure is defined as code using Terraform, making the system reproducible and deployment process is fully automated through a CI/CD pipeline with GitHub Actions.*

**Concept**: Automatically convert csv files to json format upon upload.

**Why it's a good project**: It demonstrates a powerful, event-driven architecture. Using Terraform elevates the project by making the entire setup version-controlled and fully automated, which are core concepts in modern DevOps and cloud engineering.

➡️ **Live Demo Video Here** ⬅️
(max. 15 sec)

## How it Works:
- **Terraform** is used to provision two S3 buckets: csv-uploads and json-processed.
- The Terraform configuration also sets up an **S3 Event Notification** on the csv-uploads bucket.
- When a user uploads a csv file to that bucket, the event automatically triggers an **AWS Lambda function** (managed also by Terraform).
- The Lambda code reads the csv file, converts its content to json, and saves the new json file in the json-processed bucket.

## Technology Stack:
- **Cloud Provider**: AWS (Amazon Web Services)
- **Infrastructure as Code (IaC)**: Terraform
- **CI/CD**: GitHub Actions
- **Programming Language**: Python 3.9
- **Core AWS Services**:
    - AWS Lambda (Serverless Compute)
    - Amazon S3 Object Storage (with event triggers)
    - API Gateway (for the Live Demo)
    - AWS IAM (Identity and Access Management)
    - Amazon CloudWatch (Logging and Monitoring)
