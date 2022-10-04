#
# Pre-prod environment «dev»
#

locals {
  context = "preprod"
  env     = "dev"

  tags = {
    Context     = local.context
    Environment = local.env
  }
}
