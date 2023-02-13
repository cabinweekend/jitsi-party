#
# RetroBot Lambda template
#

output "access_key" {
  value     = aws_iam_access_key.this.id
  sensitive = true
}

output "lambda_function_arn" {
  value = module.this.lambda_function_arn
}

output "lambda_function_name" {
  value = module.this.lambda_function_name
}

output "secret_key" {
  value     = aws_iam_access_key.this.secret
  sensitive = true
}
