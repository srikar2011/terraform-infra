module "vpc" {
  source          = "./modules/vpc"
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
}

module "alb" {
  source      = "./modules/alb"
  vpc_id      = module.vpc.vpc_id
  subnets     = module.vpc.subnets
  env         = var.env
  deploy_color = var.deploy_color
}

module "ecs" {
  source          = "./modules/ecs"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.subnets

  alb_sg          = module.alb.alb_sg
  tg_frontend     = module.alb.tg_frontend
  tg_backend_blue = module.alb.tg_backend_blue
  tg_backend_green = module.alb.tg_backend_green

  env             = var.env
  image_tag       = var.image_tag
  deploy_color    = var.deploy_color

  backend_repo    = var.backend_repo
  frontend_repo   = var.frontend_repo

  mongo_uri       = var.mongo_uri
}