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

# TODO: After the account is verified I can add new CloudFront resources and use the code below
# output "cloudfront_domain_name" {
#     description = "The public domain name of the CloudFront website"
#     value       = module.frontend-hosting.cloudfront_domain_name
# }

output "hosting_bucket_id" {
    description = "The name of the S3 bucket for frontend artifacts"
    value       = module.frontend-hosting.hosting_bucket_id
}

output "website_url" {
    description = "The public URL of the website"
    value       = "http://${module.frontend-hosting.website_endpoint}"
}