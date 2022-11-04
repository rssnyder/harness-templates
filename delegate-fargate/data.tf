data "aws_vpc" "lab" {
  filter {
    name   = "tag:Name"
    values = ["sa-lab"]
  }
}

data "aws_subnets" "public" {
  tags = {
    vpc  = "sa-lab"
    type = "public"
  }
}

data "aws_subnets" "private" {
  tags = {
    vpc  = "sa-lab"
    type = "private"
  }
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.lab.id
  name   = "default"
}