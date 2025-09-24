terraform {
    # This uses the S3 bucket and DynamoDB table I ALREADY created in the foundation stage (with /terraform/foundation/ terraform files)
    backend "s3" {
        bucket = "csv2json-tfstate-mz1gpchf"
        key    = "csv2json/terraform.tfstate"
        region = var.aws_region
        dynamodb_table = "csv2json-terraform-locks"
    }

    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = "~> 6.0"
        }
    }
}