#
# AuthBot Lambda template
#

variable "backfill_trigger_rule_arn" {
  description = "Backfill event bus ARN"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "AWS Cognito user pool ID"
  type        = string
}

variable "name" {
  description = "DNS-friendly name"
  type        = string
}

variable "orders_trigger_rule_arn" {
  description = "Shopify event bus ARN"
  type        = string
}

variable "shopify_pass_arn" {
  description = "Shopify password secret ARN"
  type        = string
}

variable "shopify_shop_domain" {
  description = "Shopify Shop URL"
  type        = string
}

variable "tags" {
  default     = {}
  description = "Tag set to apply to resources"
  type        = map(string)
}
