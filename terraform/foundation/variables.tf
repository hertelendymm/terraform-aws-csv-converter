variable "project_name" {
    description = "The name of the project, used to prefix resource names"
    type        = string
    default     = "csv2json"
}

variable "aws_region" {
    description = "The AWS region to deploy the backend resources in (London is the default region)"
    type        = string
    default     = "eu-west-2"
}
