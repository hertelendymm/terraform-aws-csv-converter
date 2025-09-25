data "archive_file" "lambda_zip" {
    type        = "zip"
    source_dir  = "${path.root}/../src"
    output_path = "${path.root}/lambda_payload.zip"
}

resource "random_string" "bucket_suffix" {
    length  = 8
    special = false
    upper   = false
}

resource "aws_s3_bucket" "source_bucket" {
    bucket = "${var.project_name}-source-${random_string.bucket_suffix.result}"
}

resource "aws_s3_bucket" "destination_bucket" {
    bucket = "${var.project_name}-destination-${random_string.bucket_suffix.result}"
}

resource "aws_iam_role" "lambda_exec_role" {
    name = "${var.project_name}-lambda-exec-role"

    assume_role_policy = jsonencode({
        Version   = "2012-10-17",
        Statement = [{
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
            Service = "lambda.amazonaws.com"
        }
        }]
    })
}

resource "aws_iam_policy" "lambda_policy" {
    name        = "${var.project_name}-lambda-policy"
    description = "IAM policy for the CSV to JSON converter Lambda function."

    policy = jsonencode({
        Version   = "2012-10-17",
        Statement = [
        {
            Action = [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            Effect   = "Allow",
            Resource = "arn:aws:logs:*:*:*"
        },
        {
            Action   = "s3:GetObject",
            Effect   = "Allow",
            Resource = "${aws_s3_bucket.source_bucket.arn}/*"
        },
        {
            Action   = "s3:PutObject",
            Effect   = "Allow",
            Resource = "${aws_s3_bucket.destination_bucket.arn}/*"
        }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
    role       = aws_iam_role.lambda_exec_role.name
    policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "csv_converter" {
    function_name = "${var.project_name}-converter"
    role          = aws_iam_role.lambda_exec_role.arn

    filename         = data.archive_file.lambda_zip.output_path
    source_code_hash = data.archive_file.lambda_zip.output_base64sha256
    handler          = "lambda_function.lambda_handler"
    runtime          = "python3.9"

    environment {
        variables = {
        DESTINATION_BUCKET_NAME = aws_s3_bucket.destination_bucket.id
        }
    }

    depends_on = [aws_iam_role_policy_attachment.lambda_policy_attachment]
}

resource "aws_lambda_permission" "allow_s3_to_invoke_lambda" {
    statement_id  = "AllowS3ToInvokeLambda"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.csv_converter.arn
    principal     = "s3.amazonaws.com"
    source_arn    = aws_s3_bucket.source_bucket.arn
    }

    resource "aws_s3_bucket_notification" "bucket_notification" {
    bucket = aws_s3_bucket.source_bucket.id

    lambda_function {
        lambda_function_arn = aws_lambda_function.csv_converter.arn
        events              = ["s3:ObjectCreated:*"]
        filter_suffix       = ".csv"
    }

    depends_on = [aws_lambda_permission.allow_s3_to_invoke_lambda]
}
