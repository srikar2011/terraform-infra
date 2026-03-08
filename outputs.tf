output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = module.compute.instance_id
}

output "ec2_public_ip" {
  description = "EC2 public IP"
  value       = module.compute.public_ip
}

output "ec2_private_ip" {
  description = "EC2 private IP"
  value       = module.compute.private_ip
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.loadbalancer.alb_dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = module.loadbalancer.alb_arn
}