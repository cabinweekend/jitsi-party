#
# API Gateway template
#

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_apigatewayv2_api" "current" {
  description   = "Shopify webhook API"
  name          = var.name
  protocol_type = "HTTP"

  cors_configuration {
    allow_credentials = false
    allow_headers     = []
    allow_methods     = ["POST", ]
    allow_origins     = ["*", ]
    expose_headers    = []
    max_age           = 0
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.current.id
  auto_deploy = true
  depends_on  = [aws_cloudwatch_log_group.current]
  name        = "$default"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.current.arn

    format = jsonencode({
      httpMethod              = "$context.httpMethod"
      integrationErrorMessage = "$context.integrationErrorMessage"
      protocol                = "$context.protocol"
      requestId               = "$context.requestId"
      requestTime             = "$context.requestTime"
      resourcePath            = "$context.resourcePath"
      responseLength          = "$context.responseLength"
      routeKey                = "$context.routeKey"
      sourceIp                = "$context.identity.sourceIp"
      status                  = "$context.status"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "current" {
  api_id           = aws_apigatewayv2_api.current.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.lambda_arn
}

resource "aws_apigatewayv2_route" "current" {
  api_id    = aws_apigatewayv2_api.current.id
  route_key = "POST /webhook"
  target    = "integrations/${aws_apigatewayv2_integration.current.id}"
}

resource "aws_cloudwatch_log_group" "current" {
  name              = "/aws/api_gw/${aws_apigatewayv2_api.current.name}"
  retention_in_days = 90
}

resource "aws_lambda_permission" "api_gw" {
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.current.execution_arn}/*/*"
  statement_id  = "AllowExecutionFromAPIGateway"
}
