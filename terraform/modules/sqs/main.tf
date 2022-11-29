#
# SQS module
#

locals {
  dlq_redrive_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.this.arn]
  })

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn,
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "dlq" {
  fifo_queue              = true
  name                    = "${var.name}-dlq.fifo"
  sqs_managed_sse_enabled = true
  tags                    = var.tags
}

resource "aws_sqs_queue" "this" {
  content_based_deduplication = true
  fifo_queue                  = true
  name                        = "${var.name}.fifo"
  sqs_managed_sse_enabled     = true
  tags                        = var.tags
}

resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  queue_url            = aws_sqs_queue.dlq.id
  redrive_allow_policy = local.dlq_redrive_policy
}

resource "aws_sqs_queue_redrive_policy" "this" {
  queue_url      = aws_sqs_queue.this.id
  redrive_policy = local.redrive_policy
}
