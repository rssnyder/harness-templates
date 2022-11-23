# delegate in fargate

Goal: run a nextgen harness delegate in ecs/faregate

- prereq
  - vpc
    - subnets
      - public
      - private
    - security group
  - secret in secrets manager for delegate token

- create 
  - secret manager for delegate token
  - ecs cluster (faregate in this example)
  - task/service for harness delegate
