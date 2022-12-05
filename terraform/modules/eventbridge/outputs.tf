#
# Event Bridge template
#

output "bus_arn" {
  value = data.aws_cloudwatch_event_source.shopify.arn
}

output "eventbridge_rule_arns" {
  value = module.eventbridge.eventbridge_rule_arns
}
