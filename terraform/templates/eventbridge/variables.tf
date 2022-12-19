#
# Event Bridge template
#

variable "bus_name" {
  description = "Shopify event bus name"
  type        = string
}

variable "lambda_arn" {
  description = "Order procesing lambda ARN"
  type        = string
}

variable "name" {
  description = "DNS-friendly name"
  type        = string
}

variable "tags" {
  default     = {}
  description = "Tag set to apply to resources"
  type        = map(string)
}
