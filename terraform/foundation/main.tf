# This configuration creates the founadtional resources for the Terraform remote state
# It should be aplied MANUALLY ONE TIME. So, the main pipeline can access and use the created AWS resources for the rest of the project.

resource "random_string" "suffix" {
    length  = 8
    special = false
    upper   = false
}

resource "aws_s3_bucket" "terraform_state" {
    bucket = "${var.project_name}-tfstate-${random_string.suffix.result}"

    lifecycle {
        prevent_destroy = true
    }
}

resource "aws_s3_bucket_versioning" "state_bucket_versioning" {
    bucket = aws_s3_bucket.terraform_state.id

    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_bucket_sse" {
    bucket = aws_s3_bucket.terraform_state.id

    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}

resource "aws_dynamodb_table" "terraform_locks" {
    name         = "${var.project_name}-terraform-locks"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }
}
