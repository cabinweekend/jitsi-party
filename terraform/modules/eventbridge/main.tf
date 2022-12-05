#
# Event Bridge template
#

data "aws_caller_identity" "current" {}
data "aws_cloudwatch_event_source" "shopify" { name_prefix = "aws.partner/shopify.com" }
data "aws_region" "current" {}

locals {
  create_order_rule = {
    detail      = { metadata = { X-Shopify-Topic = [{ prefix = "orders/create" }] } }
    detail-type = ["shopifyWebhook"]
  }
}

module "eventbridge" {
  bus_name    = var.bus_name
  create_bus  = false
  create_role = false
  source      = "terraform-aws-modules/eventbridge/aws"
  tags        = var.tags
  version     = "1.17.0"

  rules = {
    orders = {
      description   = "Capture order/create events"
      enabled       = true
      event_pattern = jsonencode(local.create_order_rule)
    }
  }

  targets = {
    orders = [
      {
        arn  = var.lambda_arn
        name = "${var.name}-lambda-orders"
      }
    ]
  }
}
