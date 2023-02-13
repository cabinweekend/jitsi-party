#
# Production environment for tstvhq.myshopify.com
#

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  secrets = toset(["shopify_pass", ])
}

module "secrets" {
  for_each = local.secrets
  name     = "${local.context}-${local.env}-${each.key}"
  source   = "../../../modules/secret" # FIXME: this must be replaced with a versioned reference to repository after the first release
  tags     = local.tags
}

module "eventbridge" {
  lambda_arn = module.authbot.lambda_function_arn
  bus_name   = var.bus_name
  name       = "${local.context}-${local.env}-shopify-orders"
  source     = "../../../templates/eventbridge" # FIXME: this must be replaced with a versioned reference to repository after the first release
  tags       = local.tags
}

module "authbot" {
  backfill_trigger_rule_arn = module.eventbridge.backfill_rule_arns["backfill"]
  cognito_user_pool_id      = var.cognito_user_pool_id
  name                      = "${local.context}-${local.env}-AuthBot"
  orders_trigger_rule_arn   = module.eventbridge.orders_rule_arns["orders"]
  shopify_pass_arn          = module.secrets["shopify_pass"].arn
  shopify_shop_domain       = var.shopify_shop_domain
  source                    = "../../../templates/authbot" # FIXME: this must be replaced with a versioned reference to repository after the first release
  tags                      = local.tags
}

module "retrobot" {
  backfill_bus_arn    = module.eventbridge.backfill_bus_arn
  name                = "${local.context}-${local.env}-RetroBot"
  shopify_pass_arn    = module.secrets["shopify_pass"].arn
  shopify_shop_domain = var.shopify_shop_domain
  source              = "../../../templates/retrobot" # FIXME: this must be replaced with a versioned reference to repository after the first release
  tags                = local.tags
}
