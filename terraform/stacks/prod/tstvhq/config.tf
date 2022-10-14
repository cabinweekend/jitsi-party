#
# Production environment for tstvhq.myshopify.com
#

locals {
  context = "prod"
  env     = "tstvhq"

  tags = {
    Context     = local.context
    Environment = local.env
  }
}
