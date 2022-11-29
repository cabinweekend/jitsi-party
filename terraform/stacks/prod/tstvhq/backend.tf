#
# Production environment for tstvhq.myshopify.com
#

terraform {
  backend "s3" {
    bucket = "cabinweekend-tfstate"
    key    = "prod/tstvhq/tfstate"
    region = "us-east-2"
  }
}
