locals {
  region      = "us-west-2"
  owner_split = split("/", data.aws_caller_identity.current.arn)
  owner       = element(local.owner_split, length(local.owner_split) - 1)
}

data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_group" "logs" {
  name = "${var.name}-lab-ecs"
}

resource "aws_ecs_cluster" "main" {
  name = "${var.name}-lab"
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.logs.name
      }
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.name}-ecsTaskExecutionRole"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "ecs_task_execution_role" {
  name        = "${var.name}-ecsTaskExecutionRole"
  description = "Policy that allows access to task execution"

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Effect": "Allow",
           "Action": [
               "logs:*"
           ],
           "Resource": "${aws_cloudwatch_log_group.logs.arn}:log-stream:*"
       },
       {
           "Effect": "Allow",
           "Action": [
                "secretsmanager:GetSecretValue"
           ],
           "Resource": [
            "${var.harness_delegate_token_secret}"
           ]
       }
   ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_role.arn
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.name}-ecsTaskRole"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "ecs_task_role" {
  name        = "${var.name}-ecsTaskRole"
  description = "Policy that allows access to task"

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Effect": "Allow",
           "Action": [
               "dynamodb:CreateTable",
               "dynamodb:UpdateTimeToLive",
               "dynamodb:PutItem",
               "dynamodb:DescribeTable",
               "dynamodb:ListTables",
               "dynamodb:DeleteItem",
               "dynamodb:GetItem",
               "dynamodb:Scan",
               "dynamodb:Query",
               "dynamodb:UpdateItem",
               "dynamodb:UpdateTable"
           ],
           "Resource": "*"
       }
   ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_task_role" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_role.arn
}

resource "aws_ecs_task_definition" "delegate" {
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  family                   = "harness-delegate-ng"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([{
    name      = "delegate"
    image     = "harness/delegate:latest"
    essential = true
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        awslogs-group         = aws_cloudwatch_log_group.logs.name,
        awslogs-region        = local.region,
        awslogs-stream-prefix = "delegate"
      }
    },
    secrets = [
      {
        name      = "DELEGATE_TOKEN",
        valueFrom = "${var.harness_delegate_token_secret}:::"
      }
    ],
    environment = [
      {
        name  = "ACCOUNT_ID",
        value = var.harness_account_id
      },
      # {
      #   name  = "DELEGATE_TOKEN",
      #   value = var.harness_delegate_token
      # },
      {
        name  = "DELEGATE_CHECK_LOCATION",
        value = "delegatefree.txt"
      },
      {
        name  = "DELEGATE_STORAGE_URL",
        value = "https://app.harness.io"
      },
      {
        name  = "DELEGATE_TYPE",
        value = "DOCKER"
      },
      {
        name  = "INIT_SCRIPT",
        value = "curl ifconfig.co"
      },
      {
        name  = "DEPLOY_MODE",
        value = "KUBERNETES"
      },
      {
        name  = "MANAGER_HOST_AND_PORT",
        value = "https://app.harness.io/gratis"
      },
      {
        name  = "WATCHER_CHECK_LOCATION",
        value = "current.version"
      },
      {
        name  = "WATCHER_STORAGE_URL",
        value = "https://app.harness.io/public/free/freemium/watchers"
      },
      {
        name  = "CDN_URL",
        value = "https://app.harness.io"
      },
      {
        name  = "REMOTE_WATCHER_URL_CDN",
        value = "https://app.harness.io/public/shared/watchers/builds"
      },
      {
        name  = "DELEGATE_NAME",
        value = "ecs"
      },
      {
        name  = "NEXT_GEN",
        value = "true"
      },
      {
        name  = "DELEGATE_DESCRIPTION",
        value = ""
      },
      {
        name  = "DELEGATE_TAGS",
        value = ""
      },
      {
        name  = "PROXY_MANAGER",
        value = "true"
      }
    ]
  }])
}

resource "aws_ecs_service" "delegate" {
  name            = "delegate"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.delegate.arn
  desired_count   = 1
  # deployment_minimum_healthy_percent = 100
  # deployment_maximum_percent         = 100
  launch_type         = "FARGATE"
  scheduling_strategy = "REPLICA"

  network_configuration {
    security_groups  = [data.aws_security_group.default.id]
    subnets          = data.aws_subnets.private.ids
    assign_public_ip = false
  }
}