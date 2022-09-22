#
# Pre-prod environment «dev»
#

module "apig" {
  name   = "authbot"
  source = "../../../templates/apig" # FIXME: this must be replaced with a versioned reference to repository after the first release
  tags   = local.tags
}
