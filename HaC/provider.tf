provider "aws" {
  region = "us-west-2"
}

provider "harness" {
  endpoint = "https://app.harness.io/gateway"
}
