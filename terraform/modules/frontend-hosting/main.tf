resource "aws_s3_bucket" "hosting_bucket" {
    bucket = "${var.project_name}-hosting-${random_string.bucket_suffix.result}"
}

resource "random_string" "bucket_suffix" {
    length  = 8
    special = false
    upper   = false
}

resource "aws_s3_bucket_website_configuration" "hosting_website" {
    bucket = aws_s3_bucket.hosting_bucket.id

    index_document {
        suffix = "index.html"
    }

    error_document {
        key = "index.html"
    }
}

resource "aws_s3_bucket_public_access_block" "hosting_bucket_public" {
    bucket = aws_s3_bucket.hosting_bucket.id

    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "hosting_bucket_policy" {
    bucket = aws_s3_bucket.hosting_bucket.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Sid       = "PublicReadGetObject"
                Effect    = "Allow"
                Principal = "*"
                Action    = "s3:GetObject"
                Resource  = "${aws_s3_bucket.hosting_bucket.arn}/*"
            }
        ]
    })
    
    depends_on = [aws_s3_bucket_public_access_block.hosting_bucket_public]
}

# TODO: After the account is verified I can add new CloudFront resources and use the code below

# resource "aws_s3_bucket_public_access_block" "hosting_bucket_pab" {
#     bucket = aws_s3_bucket.hosting_bucket.id

#     block_public_acls       = true
#     block_public_policy     = true
#     ignore_public_acls      = true
#     restrict_public_buckets = true
# }

# resource "aws_cloudfront_origin_access_control" "hosting_oac" {
#     name                              = "${var.project_name}-hosting-oac"
#     origin_access_control_origin_type = "s3"
#     signing_behavior                  = "always"
#     signing_protocol                  = "sigv4"
# }

# resource "aws_cloudfront_distribution" "hosting_cdn" {
#     enabled             = true
#     default_root_object = "index.html"

#     origin {
#         domain_name = aws_s3_bucket.hosting_bucket.bucket_regional_domain_name
#         origin_id   = aws_s3_bucket.hosting_bucket.id

#         origin_access_control_id = aws_cloudfront_origin_access_control.hosting_oac.id
#     }

#     default_cache_behavior {
#         allowed_methods  = ["GET", "HEAD", "OPTIONS"]
#         cached_methods   = ["GET", "HEAD"]
#         target_origin_id = aws_s3_bucket.hosting_bucket.id
#         compress         = true

#         viewer_protocol_policy = "redirect-to-https"

#         forwarded_values {
            # query_string = false
            # cookies {
            #     forward = "none"
            # }
#         }
#     }

#     custom_error_response {
#         error_caching_min_ttl = 10
#         error_code            = 403
#         response_code         = 200
#         response_page_path    = "/index.html"
#     }

#     custom_error_response {
#         error_caching_min_ttl = 10
#         error_code            = 404
#         response_code         = 200
#         response_page_path    = "/index.html"
#     }

#     restrictions {
#         geo_restriction {
#         restriction_type = "none"
#         }
#     }

#     viewer_certificate {
#         cloudfront_default_certificate = true
#     }
# }

# resource "aws_s3_bucket_policy" "hosting_bucket_policy" {
#     bucket = aws_s3_bucket.hosting_bucket.id

#     policy = jsonencode({
#         Version = "2012-10-17"
#         Statement = [{
#             Sid       = "AllowCloudFrontOAC"
#             Effect    = "Allow"
#             Principal = { Service = "cloudfront.amazonaws.com" }
#             Action    = "s3:GetObject"
#             Resource  = "${aws_s3_bucket.hosting_bucket.arn}/*"

#             Condition = {
#                 StringEquals = {
#                 "AWS:SourceArn" = aws_cloudfront_distribution.hosting_cdn.arn
#                 }
#             }
#         }]
#     })
# }
