# aws - eks - fargate

Goal: run a delegate in fargate

- create 
  - vpc (public/private)
  - ECS cluster using Fargate
  - Delegate

[install terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) and `terraform apply`

You need to create a delegate in the harness UI and then use the delegate token and account id in the input variables.

## references

[aws vpc module](https://github.com/terraform-aws-modules/terraform-aws-vpc)
