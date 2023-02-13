#
# RetroBot Lambda template
#

variable "backfill_bus_arn" {
  description = "ARN of the EventBridge backfill bus"
  type        = string
}

variable "backfill_days" {
  default     = 7
  description = "How many days of orders backfill?"
  type        = number
}

variable "name" {
  description = "DNS-friendly name"
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
