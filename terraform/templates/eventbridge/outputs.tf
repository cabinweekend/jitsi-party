#
# Event Bridge template
#

output "backfill_bus_arn" {
  value = module.backfill.eventbridge_bus_arn
}

output "backfill_rule_arns" {
  value = module.backfill.eventbridge_rule_arns
}

output "bus_arn" {
  value = data.aws_cloudwatch_event_source.shopify.arn
}

output "orders_rule_arns" {
  value = module.shopify.eventbridge_rule_arns
}
