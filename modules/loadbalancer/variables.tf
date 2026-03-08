variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "alb_sg_id" {
  type = string
}

variable "instance_id" {
  type = string
}