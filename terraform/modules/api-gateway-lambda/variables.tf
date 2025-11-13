variable "project_name" {
    description = "The name of the project, used as a prefix for all resources"
    type        = string
}

variable "source_bucket_name" {
    description = "The name of the source S3 bucket"
    type        = string
}

variable "source_bucket_arn" {
    description = "The ARN of the source S3 bucket"
    type        = string
}

variable "destination_bucket_name" {
    description = "The name of the destination S3 bucket"
    type        = string
}

variable "destination_bucket_arn" {
    description = "The ARN of the destination S3 bucket"
    type        = string
}