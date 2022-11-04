terraform {
  required_version = ">= 0.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    harness = {
      source  = "harness/harness"
      version = ">= 0.5.2"
    }
  }
}

provider "aws" {
  region = local.region
  default_tags {
    tags = {
      name       = var.name
      ttl        = "-1"
      githubRepo = "demo-qs"
      githubOrg  = "wings-software"
    }
  }
}
