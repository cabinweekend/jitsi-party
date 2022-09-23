#
# Pre-prod environment «dev»
#

module "apig" {
  name   = "authbot"
  source = "../../../templates/apig" # FIXME: this must be replaced with a versioned reference to repository after the first release
  tags   = local.tags
}

module "lambda_function" {
  attach_network_policy                   = true
  attach_policies                         = true
  attach_policy_statements                = false
  create_current_version_allowed_triggers = false
  description                             = "Echo Test"
  function_name                           = "EchoTest"
  handler                                 = "echotest.lambda_handler"
  number_of_policies                      = 1
  policies                                = ["arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole", ]
  runtime                                 = "python3.9"
  source                                  = "terraform-aws-modules/lambda/aws" # FIXME: this must be pinned to a release tag or commit hash
  source_path                             = "../../../../echotest"
  tags                                    = local.tags

  allowed_triggers = {
    sqs = {
      principal  = "sqs.amazonaws.com"
      source_arn = module.apig.queue_arn
    }
  }

  event_source_mapping = {
    sqs = {
      event_source_arn        = module.apig.queue_arn
      function_response_types = ["ReportBatchItemFailures"]
    }
  }
}
