#
# API Gateway template
#

output "api_endpoint" {
  value = aws_apigatewayv2_api.current.api_endpoint
}

output "arn" {
  value = aws_apigatewayv2_api.current.execution_arn
}
