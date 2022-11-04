variable "name" {
  type        = string
  description = "name to use for your cluster"
}

variable "harness_account_id" {
  type    = string
  default = ""
}

variable "harness_delegate_token_secret" {
  type    = string
  default = ""
}
