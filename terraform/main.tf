module "s3_lambda_pipeline" {
    source       = "./modules/s3-lambda-pipeline"
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
}