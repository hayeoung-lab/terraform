#
# Web Server
# LB - TG(ASG)
#
# 1. Default VPC
# 2. LB -TG(ASG)
# (1) ALB 생성
#     * SG 생성
#     * TG 생성
#     * LB 생성
#     * LB Listener 생성
#     * LB Listener rule 생성
# (2) ASG 생성
#     * SG 생성
#     * LT 생성(mykeypair, user_data)
#     * ASG 생성
#
# Web Server
# LB - TG(ASG)
#
# 1. Default VPC
# 2. LB -TG(ASG)
# (1) ALB 생성
#     * SG 생성
#     * TG 생성
#     * LB 생성
#     * LB Listener 생성
#     * LB Listener rule 생성
# (2) ASG 생성
#     * SG 생성
#     * LT 생성(mykeypair, user_data)
#     * ASG 생성

# ==============================================================================
# Web Server with ALB and Auto Scaling Group (ASG)
# ==============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# ------------------------------------------------------------------------------
# 1. Data Sources
# ------------------------------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "terraform_remote_state" "myRemoteState" {
  backend = "s3"
  config = {
    bucket = "bucket-bsc-7979"
    key    = "global/s3/terraform.tfstate"
    region = "us-east-2"
  }
}

# ------------------------------------------------------------------------------
# 2. Security Groups & Launch Template
# ------------------------------------------------------------------------------

resource "aws_security_group" "myInstanceSG" {
  name        = "myInstanceSG"
  description = "Security Group for EC2 Instances"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "myLaunchTemplate" {
  name          = "myLaunchTemplate"
  image_id      = "ami-06c4532923d4ba1ec"
  instance_type = "t2.micro"
  key_name      = "mykeypair"

  vpc_security_group_ids = [aws_security_group.myInstanceSG.id]

  user_data = base64encode(templatefile("user-data.sh", {
    server_port = 8080
    db_address  = data.terraform_remote_state.myRemoteState.outputs.address
    db_port     = data.terraform_remote_state.myRemoteState.outputs.port
  }))

  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------------------------------------------------------
# 3. ALB & Target Group
# ------------------------------------------------------------------------------

resource "aws_security_group" "myALB-SG" {
  name   = "myALB-SG"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "myALB" {
  name               = "myALB"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.myALB-SG.id]
}

resource "aws_lb_target_group" "myALB-TG" {
  name     = "myALB-TG"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "myALB-Listener" {
  load_balancer_arn = aws_lb.myALB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "myALB-Listener-Rule" {
  listener_arn = aws_lb_listener.myALB-Listener.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myALB-TG.arn
  }
}

# ------------------------------------------------------------------------------
# 4. Auto Scaling Group (ASG) - 이미지 내용 반영
# ------------------------------------------------------------------------------

resource "aws_autoscaling_group" "bar" {
  vpc_zone_identifier = data.aws_subnets.default.ids
  desired_capacity     = 2
  max_size             = 10
  min_size             = 1

  # Target Group 연동 및 생성 순서 보장 (depends_on)
  target_group_arns = [aws_lb_target_group.myALB-TG.arn]
  depends_on        = [aws_lb_target_group.myALB-TG]

  # Launch Template 설정
  launch_template {
    id      = aws_launch_template.myLaunchTemplate.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "myASG"
    propagate_at_launch = true
  }
}