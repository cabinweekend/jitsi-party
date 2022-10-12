#
# Secret module
#

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_secretsmanager_secret" "this" {
  name = "${var.name}-${random_id.suffix.hex}"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.value
}
