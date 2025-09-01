resource "aws_lb" "this" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids
}

# Derive VPC ID from one of the provided subnets
data "aws_subnet" "first_public" {
  id = var.public_subnet_ids[0]
}

resource "aws_lb_target_group" "tg" {
  name     = "${var.project_name}-tg"
  port     = var.target_port
  protocol = "HTTP"
  vpc_id   = data.aws_subnet.first_public.vpc_id

  health_check {
    enabled             = true
    path                = var.health_check_path
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_listener" "https" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}