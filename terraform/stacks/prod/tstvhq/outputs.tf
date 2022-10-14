#
# Production environment for tstvhq.myshopify.com
#

locals {
  webhook_payload = {
    webhook = {
      address = module.apig.api_endpoint
      fields  = ["customer", "id", "line_items", ]
      format  = "json"
      topic   = "orders/create"
    }
  }
  export_secrets = join("\n", [for k, v in module.secrets : "$ export ${k}='VALUE_HERE'"])
  populate_secrets = join("\n", [for k, v in module.secrets :
    "$ aws secretsmanager put-secret-value --secret-id ${v.arn} --secret-string \"$${${k}}\""
  ])
}

output "manual_steps" {
  value = <<EOT
Manual steps are required to finish system setup. First, populate environment:

${local.export_secrets}

Then populate secrets:

${local.populate_secrets}

And finally, register the Webhook:

$ curl -d '${jsonencode(local.webhook_payload)}' \
-X POST "https://${var.shopify_shop_url}/admin/api/2022-07/webhooks.json" \
-H "X-Shopify-Access-Token: $${shopify_pass}" \
-H "Content-Type: application/json"

EOT
}
