#
# API Gateway template
#

variable "lambda_arn" {
  description = "Lambda function ARN"
  type        = string
}

variable "lambda_name" {
  description = "Lambda function name"
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
