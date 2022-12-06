#
# Pre-prod environment «dev»
#

terraform {
  backend "s3" {
    bucket = "cabinweekend-tfstate"
    key    = "preprod/dev/tfstate"
    region = "us-east-2"
  }
}
