module "s3_lambda_pipeline" {
    source       = "./modules/s3-lambda-pipeline"
    project_name = var.project_name
    aws_region   = var.aws_region
    frontend_website_url = "http://${module.frontend-hosting.website_endpoint}"
}

module "frontend-hosting" {
    source       = "./modules/frontend-hosting"
    project_name = var.project_name
    aws_region   = var.aws_region
}

module "api_gateway_lambda" {
    source = "./modules/api-gateway-lambda"

    project_name = var.project_name
    
    source_bucket_name      = module.s3_lambda_pipeline.source_bucket_name
    source_bucket_arn       = module.s3_lambda_pipeline.source_bucket_arn
    destination_bucket_name = module.s3_lambda_pipeline.destination_bucket_name
    destination_bucket_arn  = module.s3_lambda_pipeline.destination_bucket_arn

    frontend_domain         = "http://${module.frontend-hosting.website_endpoint}"

    # TODO: After the account is verified I can add new CloudFront resources and use the code below
    # frontend_domain         = "https://${module.frontend-hosting.cloudfront_domain_name}"

    depends_on              = [module.frontend-hosting]
}