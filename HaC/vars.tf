variable "org" {
  type = string
}

variable "requestor" {
  type    = string
  default = "vending-machine"
}

variable "approvers" {
  type    = list(string)
  default = []
}

variable "git_connector" {
  type    = string
  default = "account.rssnyder"
}

variable "dev_k8s_connector" {
  type    = string
  default = "account.sagcp"
}

variable "staging_k8s_connector" {
  type    = string
  default = "account.sagcp"
}

variable "production_k8s_connector" {
  type    = string
  default = "account.sagcp"
}