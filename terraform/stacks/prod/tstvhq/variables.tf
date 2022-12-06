#
# Production environment for tstvhq.myshopify.com
#

variable "cognito_user_pool_id" {
  description = "AWS Cognito user pool ID"
  type        = string
}

variable "shopify_shop_url" {
  description = "Shopify Shop URL"
  type        = string
}
