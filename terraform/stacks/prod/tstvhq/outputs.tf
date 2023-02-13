#
# Production environment for tstvhq.myshopify.com
#

locals {
  webhook_payload = {
    webhook = {
      address = module.eventbridge.bus_arn
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

output "github_user_access_key" {
  value     = module.retrobot.access_key
  sensitive = true
}

output "github_user_secret_key" {
  value     = module.retrobot.secret_key
  sensitive = true
}

output "manual_steps" {
  value = <<EOT
Manual steps are required to finish system setup. First, populate environment:

${local.export_secrets}

Then populate secrets:

${local.populate_secrets}

And finally, register the Webhook:

$ curl -d '${jsonencode(local.webhook_payload)}' \
-X POST "https://${var.shopify_shop_domain}/admin/api/2022-07/webhooks.json" \
-H "X-Shopify-Access-Token: $${shopify_pass}" \
-H "Content-Type: application/json"

EOT
}

output "retrobot_lambda_function_name" {
  value = module.retrobot.lambda_function_name
}
