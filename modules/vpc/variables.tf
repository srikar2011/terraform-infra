variable "vpc_cidr" {
  description = "VPC CIDR block"
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}