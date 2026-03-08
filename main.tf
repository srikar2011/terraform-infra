# Root main.tf - calls all modules

module "security" {
  source      = "./modules/security"
  vpc_id      = var.vpc_id
  app_name    = var.app_name
  environment = var.environment
}

module "compute" {
  source        = "./modules/compute"
  ami_id        = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.ec2_subnet_id
  app_name      = var.app_name
  environment   = var.environment
  key_pair_name = var.key_pair_name
  ec2_sg_id     = module.security.ec2_sg_id
}

module "loadbalancer" {
  source      = "./modules/loadbalancer"
  vpc_id      = var.vpc_id
  subnet_ids  = var.subnet_ids
  app_name    = var.app_name
  environment = var.environment
  alb_sg_id   = module.security.alb_sg_id
  instance_id = module.compute.instance_id
}

module "networking" {
  source      = "./modules/networking"
  vpc_id      = var.vpc_id
  app_name    = var.app_name
  environment = var.environment
}

module "database" {
  source                = "./modules/database"
  app_name              = var.app_name
  environment           = var.environment
  subnet_ids            = var.subnet_ids
  db_sg_id              = module.security.db_sg_id
  multi_az              = var.multi_az
  backup_retention_days = var.backup_retention_days
}