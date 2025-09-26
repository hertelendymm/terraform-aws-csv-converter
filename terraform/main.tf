module "s3_lambda_pipeline" {
    source       = "./modules/s3-lambda-pipeline"
    project_name = var.project_name
    aws_region   = var.aws_region
}