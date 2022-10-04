#
# Pre-prod environment «dev»
#

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "validate-and-enqueue" {
  attach_network_policy                   = true
  attach_policy_statements                = false
  attach_policy_json                      = true
  create_current_version_allowed_triggers = false
  description                             = "Validate and enqueue Shopify order"
  function_name                           = "validate-and-enqueue"
  handler                                 = "vae.lambda_handler"
  number_of_policies                      = 1
  runtime                                 = "python3.9"
  source                                  = "terraform-aws-modules/lambda/aws" # FIXME: this must be pinned to a release tag or commit hash
  source_path                             = "../../../../validate-and-enqueue"
  tags                                    = local.tags

  allowed_triggers = {
    apig = {
      service    = "apigateway"
      source_arn = module.apig.arn
    },
  }

  environment_variables = {
    API_SHARED_SECRET = var.shopify_api_shared_secret
    SQS_QUEUE_URL     = module.sqs.url
  }

  policy_json = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["sqs:SendMessage"],
      Resource = [module.sqs.arn]
    }]
  })
}

module "apig" {
  lambda_arn  = module.validate-and-enqueue.lambda_function_arn
  lambda_name = module.validate-and-enqueue.lambda_function_name
  name        = "authbot"
  source      = "../../../templates/apig" # FIXME: this must be replaced with a versioned reference to repository after the first release
  tags        = local.tags
}

module "sqs" {
  name   = "shopify-orders"
  source = "../../../modules/sqs"
}

module "authbot" {
  attach_network_policy                   = false
  attach_policies                         = true
  attach_policy_statements                = true
  create_current_version_allowed_triggers = false
  description                             = "Auth Bot"
  function_name                           = "AuthBot"
  handler                                 = "authbot.lambda_handler"
  number_of_policies                      = 1
  policies                                = ["arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole", ]
  runtime                                 = "python3.9"
  source                                  = "terraform-aws-modules/lambda/aws" # FIXME: this must be pinned to a release tag or commit hash
  source_path                             = "../../../../authbot2"
  tags                                    = local.tags
  timeout                                 = "120"

  allowed_triggers = {
    sqs = {
      principal  = "sqs.amazonaws.com"
      source_arn = module.sqs.arn
    }
  }

  environment_variables = {
    AWS_COGNITO_USER_POOL_ID = var.cognito_user_pool_id
    SHOPIFY_KEY              = var.shopify_key
    SHOPIFY_PASS             = var.shopify_pass
  }

  event_source_mapping = {
    sqs = {
      event_source_arn        = module.sqs.arn
      function_response_types = ["ReportBatchItemFailures"]
    }
  }

  policy_statements = {
    cognito_idp = {
      effect = "Allow"
      actions = [
        "cognito-idp:AdminAddUserToGroup",
        "cognito-idp:AdminCreateUser",
      ]
      resources = ["arn:aws:cognito-idp:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:userpool/${var.cognito_user_pool_id}"]
    }
  }
}
