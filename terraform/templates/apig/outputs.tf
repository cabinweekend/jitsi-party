#
# API Gateway template
#

output "arn" {
  value = aws_apigatewayv2_api.current.execution_arn
}
