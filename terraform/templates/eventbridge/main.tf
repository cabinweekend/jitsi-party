#
# Event Bridge template
#

data "aws_caller_identity" "current" {}
data "aws_cloudwatch_event_source" "shopify" { name_prefix = var.bus_name }
data "aws_region" "current" {}

locals {
  backfill_rule = { detail-type = ["retrobot"] }
  order_rule = {
    detail      = { metadata = { X-Shopify-Topic = [{ prefix = "orders/create" }] } }
    detail-type = ["shopifyWebhook"]
  }
}

module "shopify" {
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
      event_pattern = jsonencode(local.order_rule)
    }
  }

  targets = {
    orders = [{
      arn  = var.lambda_arn
      name = "${var.name}-lambda-orders"
    }]
  }
}

module "backfill" {
  bus_name    = "${var.name}-backfill"
  create_bus  = true
  create_role = true
  source      = "terraform-aws-modules/eventbridge/aws"
  tags        = var.tags
  version     = "1.17.0"

  rules = {
    backfill = {
      description   = "Capture order backfill events"
      enabled       = true
      event_pattern = jsonencode(local.backfill_rule)
    }
  }

  targets = {
    backfill = [{
      arn  = var.lambda_arn
      name = "${var.name}-lambda-orders-backfill"
    }]
  }
}
