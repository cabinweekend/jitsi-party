#
# SQS module
#

resource "aws_sqs_queue" "this" {
  content_based_deduplication = true
  fifo_queue                  = true
  name                        = "${var.name}.fifo"
  sqs_managed_sse_enabled     = true
  tags                        = var.tags
}
