#
# Production environment for tstvhq.myshopify.com
#

variable "bus_name" {
  description = "Shopify event bus name"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "AWS Cognito user pool ID"
  type        = string
}

variable "shopify_shop_domain" {
  description = "Shopify Shop URL"
  type        = string
}
