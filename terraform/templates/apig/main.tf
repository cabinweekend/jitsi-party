#
# API Gateway template
#

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_sqs_queue" "this" {
  content_based_deduplication = true
  fifo_queue                  = true
  name                        = "${var.name}-inbound-queue.fifo"
  sqs_managed_sse_enabled     = true
  tags                        = var.tags
}


# TODO: move to bootstrap: must be set up once per region.
resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

resource "aws_api_gateway_rest_api" "this" {
  name = "${var.name}-apig"
}

resource "aws_api_gateway_resource" "webhook_resource" {
  path_part   = "webhook"
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_resource" "webhook_shopify_resource" {
  path_part   = "shopify"
  parent_id   = aws_api_gateway_resource.webhook_resource.id
  rest_api_id = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_method" "webhook_shopify_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.webhook_shopify_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_settings" "webhook_shopify_post_method_settings" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "${aws_api_gateway_resource.webhook_shopify_resource.path_part}/${aws_api_gateway_method.webhook_shopify_post_method.http_method}"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

resource "aws_api_gateway_integration" "this" { #TODO: review
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.webhook_shopify_resource.id
  http_method             = aws_api_gateway_method.webhook_shopify_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  credentials             = aws_iam_role.apig-sqs-send-msg-role.arn
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:sqs:path/${data.aws_caller_identity.current.account_id}/${aws_sqs_queue.this.name}"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    # NOTE: For the SQS FIFO queue to work porperly, template needs to provide
    # request parameters Action, MessageGroupId, and MessageBody.
    "application/json" = "Action=SendMessage&MessageGroupId=1&MessageBody=${file("${path.module}/request_template.json")}"
  }
  passthrough_behavior = "WHEN_NO_TEMPLATES" # TODO: Consider setting to «NEVER»
}

# NOTE: method response and integration are used to always return 200.  This
# will prevent Shopify API to automatically unsubscribe webhooks.  See [1] and
# [2].
#
# [1] https://shopify.dev/apps/webhooks/best-practices#respond-quickly
# [2] https://shopify.dev/apps/webhooks/configuration/https#step-6-respond-to-the-webhook
resource "aws_api_gateway_method_response" "webhook_shopify_post_method_response_200" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.webhook_shopify_resource.id
  http_method = aws_api_gateway_method.webhook_shopify_post_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "webhook_shopify_post_integration_response_200" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.webhook_shopify_resource.id
  http_method = aws_api_gateway_method.webhook_shopify_post_method.http_method
  status_code = aws_api_gateway_method_response.webhook_shopify_post_method_response_200.status_code
}


resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.webhook_shopify_resource.id,
      aws_api_gateway_method.webhook_shopify_post_method.id,
      aws_api_gateway_integration.this.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = "dev" # FIXME: hardcoded value
}

resource "aws_cloudwatch_log_group" "webhook_shopify_log_group" {
  name              = "APIG-Execution-Logs_${aws_api_gateway_rest_api.this.name}"
  retention_in_days = 30
}
