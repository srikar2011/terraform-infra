resource "aws_security_group" "alb_sg" {
  vpc_id = var.vpc_id

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

resource "aws_lb" "alb" {
  name               = "tm-alb-${var.env}"
  load_balancer_type = "application"
  subnets            = var.subnets
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "frontend" {
  name        = "tg-frontend-${var.env}"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

}

resource "aws_lb_target_group" "backend_blue" {
  name        = "tg-backend-blue-${var.env}"
  port        = 3001
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"


  health_check {
    path = "/hello"
  }
}

resource "aws_lb_target_group" "backend_green" {
  name        = "tg-backend-green-${var.env}"
  port        = 3001
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"


  health_check {
    path = "/hello"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = var.deploy_color == "blue" ? aws_lb_target_group.backend_blue.arn : aws_lb_target_group.backend_green.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

output "alb_dns" {
  value = aws_lb.alb.dns_name
}

output "alb_sg" {
  value = aws_security_group.alb_sg.id
}

output "tg_frontend" {
  value = aws_lb_target_group.frontend.arn
}

output "tg_backend_blue" {
  value = aws_lb_target_group.backend_blue.arn
}

output "tg_backend_green" {
  value = aws_lb_target_group.backend_green.arn
}