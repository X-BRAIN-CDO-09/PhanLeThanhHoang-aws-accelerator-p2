resource "aws_lb" "k8s_alb" {
  name               = "k8s-counter-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.subnet_ids
}

resource "aws_lb_target_group" "k8s_tg" {
  name     = "k8s-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    port                = tostring(var.app_port)
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
  }
}

resource "aws_lb_listener" "k8s_listener" {
  load_balancer_arn = aws_lb.k8s_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "k8s_tg_attachment" {
  target_group_arn = aws_lb_target_group.k8s_tg.arn
  target_id        = var.instance_id
  port             = var.app_port
}
