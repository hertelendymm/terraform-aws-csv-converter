# This uses the S3 bucket and DynamoDB table I ALREADY created in the foundation stage (with /terraform/foundation/ terraform files)

terraform {
    backend "s3" {
        # Configuration will be provided via the init command
    }

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}