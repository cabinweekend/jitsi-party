#
# Pre-prod environment «dev»
#

variable "cognito_user_pool_id" {
  description = "AWS Cognito user pool ID"
  type        = string
}

variable "shopify_api_shared_secret" {
  description = "Shopify API shared secret"
  sensitive   = true
  type        = string
}

variable "shopify_key" {
  description = "Shopify API Key"
  sensitive   = true
  type        = string
}

variable "shopify_pass" {
  description = "Shopify API Pass"
  sensitive   = true
  type        = string
}
