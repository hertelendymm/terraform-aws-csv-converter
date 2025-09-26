output "source_bucket_name" {
    description = "The name of the S3 bucket where CSV files should be uploaded"
    value       = aws_s3_bucket.source_bucket.id
}

output "destination_bucket_name" {
    description = "The name of the S3 bucket where JSON files will be stored"
    value       = aws_s3_bucket.destination_bucket.id
}

