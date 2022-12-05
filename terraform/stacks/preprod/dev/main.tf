#
# Pre-prod environment «dev»
#

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  secrets = toset(["shopify_pass", ])
}

module "secrets" {
  for_each = local.secrets
  name     = "${local.context}-${local.env}-${each.key}"
  source   = "../../../modules/secret"
  tags     = local.tags
}

module "eventbridge" {
  lambda_arn = module.authbot.lambda_function_arn
  bus_name   = var.bus_name
  name       = "${local.context}-${local.env}-shopify-orders"
  source     = "../../../modules/eventbridge" # FIXME: this must be replaced with a versioned reference to repository after the first release
  tags       = local.tags
}

module "authbot" {
  cognito_user_pool_id = var.cognito_user_pool_id
  name                 = "${local.context}-${local.env}-AuthBot"
  shopify_pass_arn     = module.secrets["shopify_pass"].arn
  shopify_shop_url     = var.shopify_shop_url
  source               = "../../../templates/authbot" # FIXME: this must be replaced with a versioned reference to repository after the first release
  tags                 = local.tags
  trigger_rule_arn     = module.eventbridge.eventbridge_rule_arns["orders"]
}
