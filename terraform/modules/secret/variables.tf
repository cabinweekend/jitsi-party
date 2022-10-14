#
# Secret module
#

variable "name" {
  description = "Secret name"
  type        = string
}

variable "tags" {
  default     = {}
  description = "Tag set to apply to resources"
  type        = map(string)
}
