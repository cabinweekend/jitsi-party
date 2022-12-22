#
# RetroBot Lambda template
#

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "this" {
  attach_policies                         = true
  attach_policy_statements                = true
  create_current_version_allowed_triggers = false
  description                             = "Retro Bot"
  function_name                           = var.name
  handler                                 = "retrobot.lambda_handler"
  number_of_policies                      = 1
  policies                                = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", ]
  runtime                                 = "python3.9"
  source                                  = "terraform-aws-modules/lambda/aws"
  source_path                             = "../../../../retrobot"
  tags                                    = var.tags
  timeout                                 = "30"
  version                                 = "4.7.1"

  environment_variables = {
    BACKFILL_BUS_ARN    = var.backfill_bus_arn
    BACKFILL_DAYS       = var.backfill_days
    SHOPIFY_PASS_ARN    = var.shopify_pass_arn
    SHOPIFY_SHOP_DOMAIN = var.shopify_shop_domain
  }

  policy_statements = {
    events = {
      actions   = ["events:PutEvents"]
      effect    = "Allow"
      resources = [var.backfill_bus_arn]
    }
    secrets = {
      actions   = ["secretsmanager:GetSecretValue"]
      effect    = "Allow"
      resources = [var.shopify_pass_arn]
    }
  }
}

# module "topic" {
#   name    = "RetroBotMessages"
#   source  = "terraform-aws-modules/sns/aws"
#   version = "~> 3.0"
#   tags    = var.tags
# }

# module "alarm" {
#   alarm_actions       = [module.topic.sns_topic_arn]
#   alarm_description   = "RetroBot2 errors"
#   alarm_name          = "${var.name}-errors"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 1
#   metric_name         = "Errors"
#   dimensions          = { FunctionName = module.this.lambda_function_name }
#   treat_missing_data  = "notBreaching"
#   period              = 300
#   source              = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
#   statistic           = "Maximum"
#   namespace           = "AWS/Lambda"
#   threshold           = 0
#   version             = "~> 3.0"
#   tags                = var.tags
# }
