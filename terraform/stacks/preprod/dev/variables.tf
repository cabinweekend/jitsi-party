#
# Pre-prod environment «dev»
#

variable "cognito_user_pool_id" {
  description = "AWS Cognito user pool ID"
  type        = string
}

variable "shopify_api_shared_secret" {
  description = "Shopify API shared secret"
  type        = string
}

variable "shopify_key" {
  description = "Shopify API Key"
  type        = string
}

variable "shopify_pass" {
  description = "Shopify API Pass"
  type        = string
}
