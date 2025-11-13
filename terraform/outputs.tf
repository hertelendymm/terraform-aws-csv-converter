output "source_bucket_name" {
    description = "The name of the S3 bucket where CSV files should be uploaded"
    value       = module.s3_lambda_pipeline.source_bucket_name
}

output "destination_bucket_name" {
    description = "The name of the S3 bucket where JSON files will be stored"
    value       = module.s3_lambda_pipeline.destination_bucket_name
}

output "api_endpoint_url" {
    description = "The public invoke URL for the API Gateway"
    value       = module.api_gateway_lambda.api_endpoint_url
}