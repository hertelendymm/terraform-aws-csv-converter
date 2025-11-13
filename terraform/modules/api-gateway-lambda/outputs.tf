output "api_endpoint_url" {
    description = "The public invoke URL for the API Gateway"
    value       = aws_apigatewayv2_api.http_api.api_endpoint
}