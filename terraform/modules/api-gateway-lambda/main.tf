data "archive_file" "api_lambda_zip" {
    type        = "zip"
    source_dir  = "${path.root}/../src"
    output_path = "${path.root}/api_lambda_payload.zip"
}

resource "aws_iam_role" "api_lambda_exec_role" {
    name = "${var.project_name}-api-lambda-exec-role"
    assume_role_policy = jsonencode({
        Version   = "2012-10-17",
        Statement = [{
            Action    = "sts:AssumeRole",
            Effect    = "Allow",
            Principal = { Service = "lambda.amazonaws.com" }
        }]
    })
}

resource "aws_iam_policy" "api_lambda_policy" {
    name   = "${var.project_name}-api-lambda-policy"
    policy = jsonencode({
        Version   = "2012-10-17",
        Statement = [
            {
                Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
                Effect   = "Allow",
                Resource = "arn:aws:logs:*:*:*"
            },
            {
                Action   = "s3:ListBucket",
                Effect   = "Allow",
                Resource = var.destination_bucket_arn
            },
            {
                Action   = "s3:GetObject",
                Effect   = "Allow",
                Resource = "${var.destination_bucket_arn}/*"
            },
            {
                Action   = "s3:PutObject",
                Effect   = "Allow",
                Resource = "${var.source_bucket_arn}/*"
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "api_lambda_policy_attachment" {
    role       = aws_iam_role.api_lambda_exec_role.name
    policy_arn = aws_iam_policy.api_lambda_policy.arn
}

resource "aws_lambda_function" "api_handler" {
    function_name    = "${var.project_name}-api-handler"
    role             = aws_iam_role.api_lambda_exec_role.arn
    
    handler          = "api_handler.lambda_handler"
    runtime          = "python3.9"
    
    filename         = data.archive_file.api_lambda_zip.output_path
    source_code_hash = data.archive_file.api_lambda_zip.output_base64sha256
    timeout          = 30

    environment {
        variables = {
            SOURCE_BUCKET_NAME      = var.source_bucket_name
            DESTINATION_BUCKET_NAME = var.destination_bucket_name
        }
    }

    depends_on = [aws_iam_role_policy_attachment.api_lambda_policy_attachment]
}

resource "aws_apigatewayv2_api" "http_api" {
    name          = "${var.project_name}-api"
    protocol_type = "HTTP"
    
    cors_configuration {
        allow_origins = ["*"]
        allow_methods = ["GET", "OPTIONS"]
        allow_headers = ["Content-Type"]
    }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
    api_id                 = aws_apigatewayv2_api.http_api.id
    integration_type       = "AWS_PROXY"
    integration_uri        = aws_lambda_function.api_handler.invoke_arn
    payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_files" {
    api_id    = aws_apigatewayv2_api.http_api.id
    route_key = "GET /files"
    target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "get_upload_url" {
    api_id    = aws_apigatewayv2_api.http_api.id
    route_key = "GET /files/{fileName}/upload"
    target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "get_download_url" {
    api_id    = aws_apigatewayv2_api.http_api.id
    route_key = "GET /files/{fileName}/download"
    target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default_stage" {
    api_id      = aws_apigatewayv2_api.http_api.id
    name        = "$default"
    auto_deploy = true
}

resource "aws_lambda_permission" "api_gw_permission" {
    statement_id  = "AllowAPIGatewayToInvoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.api_handler.function_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}