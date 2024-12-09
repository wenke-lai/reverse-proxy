terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      Module = "reverse-proxy"
      Name   = "reverse-proxy"
      Owner  = "Neil"
    }
  }
}

data "aws_vpc" "default" {
  id = var.vpc_id
}

data "aws_subnet" "default" {
  id = var.subnet_id
}

data "aws_security_group" "default" {
  id = var.security_group_id
}

data "aws_lb" "default" {
  name = var.lb_name
}

data "aws_acm_certificate" "default" {
  domain   = "*.anyinsight.ai"
  statuses = ["ISSUED"]
}

data "aws_iam_role" "default" {
  name = var.iam_role_name
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_lb_target_group" "reverse-proxy" {
  name        = "reverse-proxy"
  port        = 9127
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "resource-proxy" {
  load_balancer_arn = data.aws_lb.default.arn
  port              = 9127
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.default.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.reverse-proxy.arn
  }
}

resource "aws_iam_instance_profile" "reverse-proxy" {
  name = "reverse-proxy"
  role = data.aws_iam_role.default.name
}

resource "aws_launch_template" "reverse-proxy" {
  name          = "reverse-proxy"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  user_data     = filebase64("${path.module}/user-data.sh")

  credit_specification {
    cpu_credits = "standard"
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.reverse-proxy.name
  }

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 10
      volume_type = "gp3"
    }
  }

}

resource "aws_instance" "reverse-proxy" {
  subnet_id              = data.aws_subnet.default.id
  vpc_security_group_ids = [data.aws_security_group.default.id]

  launch_template {
    id      = aws_launch_template.reverse-proxy.id
    version = "$Latest"
  }
}

resource "aws_lb_target_group_attachment" "reverse-proxy" {
  target_group_arn = aws_lb_target_group.reverse-proxy.arn
  target_id        = aws_instance.reverse-proxy.id
  port             = 9127
}
