output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}

output "alb_arn" {
  value = aws_lb.web_alb.arn
}

output "tg_arn" {
  value = aws_lb_target_group.web_tg.arn
}