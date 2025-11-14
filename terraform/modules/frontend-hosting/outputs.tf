output "hosting_bucket_id" {
    description = "The ID (name) of the S3 bucket for hosting"
    value       = aws_s3_bucket.hosting_bucket.id
}

# TODO: After the account is verified I can add new CloudFront resources and use the code below
# output "cloudfront_domain_name" {
#     description = "The domain name of the CloudFront distribution"
#     value       = aws_cloudfront_distribution.hosting_cdn.domain_name
# }

output "website_endpoint" {
    description = "The public URL of the S3 website"
    value       = aws_s3_bucket_website_configuration.hosting_website.website_endpoint
}
