variable "aws_region" {
  default = "ap-south-1"
}

variable "env" {}
variable "image_tag" {}
variable "deploy_color" {}

variable "backend_repo" {}
variable "frontend_repo" {}

variable "mongo_uri" {}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "mongo_ssm_parameter" {
  description = "SSM parameter name for Mongo URI"
}