terraform {
    required_version = ">= 1.13.1"

    # For this initial run, I use a local backend. After these resources are created, the main pipeline will use the created S3 backend on AWS
    backend "local" {}

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}
