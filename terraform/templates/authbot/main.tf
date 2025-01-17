#
# AuthBot Lambda template
#

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "this" {
  attach_policies                         = true
  attach_policy_statements                = true
  create_current_version_allowed_triggers = false
  description                             = "Auth Bot"
  function_name                           = var.name
  handler                                 = "authbot.lambda_handler"
  number_of_policies                      = 1
  policies                                = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", ]
  reserved_concurrent_executions          = 2
  runtime                                 = "python3.9"
  source                                  = "terraform-aws-modules/lambda/aws"
  source_path                             = "../../../../authbot2"
  tags                                    = var.tags
  timeout                                 = "30"
  version                                 = "4.7.1"

  allowed_triggers = {
    OrdersRule = {
      principal  = "events.amazonaws.com"
      source_arn = var.orders_trigger_rule_arn
    }
    BackfillRule = {
      principal  = "events.amazonaws.com"
      source_arn = var.backfill_trigger_rule_arn
    }
  }

  environment_variables = {
    AWS_COGNITO_USER_POOL_ID = var.cognito_user_pool_id
    SHOPIFY_PASS_ARN         = var.shopify_pass_arn
    SHOPIFY_SHOP_DOMAIN      = var.shopify_shop_domain
  }

  policy_statements = {
    cognito_idp = {
      actions   = ["cognito-idp:AdminAddUserToGroup", "cognito-idp:AdminCreateUser", "cognito-idp:CreateGroup", "cognito-idp:ListGroups", ]
      effect    = "Allow"
      resources = ["arn:aws:cognito-idp:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:userpool/${var.cognito_user_pool_id}"]
    }

    secrets = {
      actions   = ["secretsmanager:GetSecretValue"]
      effect    = "Allow"
      resources = [var.shopify_pass_arn]
    }
  }
}

module "topic" {
  name    = var.name
  source  = "terraform-aws-modules/sns/aws"
  version = "~> 3.0"
  tags    = var.tags
}

module "alarm" {
  alarm_actions       = [module.topic.sns_topic_arn]
  alarm_description   = "AuthBot2 errors"
  alarm_name          = "${var.name}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  dimensions          = { FunctionName = module.this.lambda_function_name }
  treat_missing_data  = "notBreaching"
  period              = 300
  source              = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  statistic           = "Maximum"
  namespace           = "AWS/Lambda"
  threshold           = 0
  version             = "~> 3.0"
  tags                = var.tags
}
