variable "vpc_id" {}
variable "subnets" {}

variable "alb_sg" {}

variable "tg_frontend" {}
variable "tg_backend_blue" {}
variable "tg_backend_green" {}

variable "env" {}
variable "image_tag" {}
variable "deploy_color" {}

variable "backend_repo" {}
variable "frontend_repo" {}

variable "mongo_uri" {}

variable "mongo_ssm_parameter" {
  type = string
}