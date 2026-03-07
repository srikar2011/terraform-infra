output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}

output "ec2_private_ip" {
  description = "EC2 private IP"
  value       = aws_instance.web.private_ip
}

output "ec2_public_ip" {
  description = "EC2 public IP"
  value       = aws_instance.web.public_ip
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.web_alb.dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.web_alb.arn
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = aws_lb_target_group.web_tg.arn
}