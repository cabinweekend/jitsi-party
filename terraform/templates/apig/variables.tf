#
# API Gateway template
#

variable "name" {
  description = "DNS-friendly name"
  type        = string
}

variable "tags" {
  default     = {}
  description = "Tag set to apply to resources"
  type        = map(string)
}
