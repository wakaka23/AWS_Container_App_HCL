########################
# ALB
########################

# Define internal ALB
resource "aws_lb" "internal" {
  name               = "${var.common.env}-alb-internal"
  internal           = true
  load_balancer_type = "application"
  subnets            = var.network.private_subnet_for_container_ids
  security_groups    = [var.network.security_group_for_internal_alb_id]
  tags = {
    Name = "${var.common.env}-alb-internal"
  }
}

# (Blue) Define the listner for internal ALB
resource "aws_lb_listener" "internal_blue" {
  load_balancer_arn = aws_lb.internal.arn
  protocol          = "HTTP"
  port              = "80"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_blue.arn
  }
}

# (Blue) Define target group for internal ALB
resource "aws_lb_target_group" "internal_blue" {
  name        = "${var.common.env}-tg-backend-blue"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.network.vpc_id
  health_check {
    protocol            = "HTTP"
    path                = "/healthcheck"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
    matcher             = 200
  }
}

# (Green) Define the listner for internal ALB
resource "aws_lb_listener" "internal_green" {
  load_balancer_arn = aws_lb.internal.arn
  protocol          = "HTTP"
  port              = "10080"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_blue.arn
  }
}

# (Green) Define target group for internal ALB
resource "aws_lb_target_group" "internal_green" {
  name        = "${var.common.env}-tg-backend-green"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.network.vpc_id
  health_check {
    protocol            = "HTTP"
    path                = "/healthcheck"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
    matcher             = 200
  }
}
