#
# SQS module
#

variable "name" {
  description = "DNS-friendly name. Requisite '.fifo' will be added by this module."
  type        = string
}

variable "tags" {
  default     = {}
  description = "Tag set to apply to resources"
  type        = map(string)
}
