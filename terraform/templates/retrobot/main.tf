#
# RetroBot Lambda template
#

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  policy = {
    Version = "2012-10-17"
    Statement = [{
      Action   = "lambda:InvokeFunction"
      Effect   = "Allow"
      Resource = module.this.lambda_function_arn
    }]
  }
}

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

resource "aws_iam_user" "this" {
  name = "${var.name}-github"
  tags = var.tags
}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}

resource "aws_iam_user_policy" "this" {
  user   = aws_iam_user.this.name
  policy = jsonencode(local.policy)
}
