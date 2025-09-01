module "vpc" {
  source               = "./modules/vpc"
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "security" {
  source             = "./modules/security"
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = var.vpc_cidr
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
}

module "alb" {
  source                = "./modules/alb"
  project_name          = var.project_name
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security.alb_sg_id
  target_port           = 80
  enable_https          = var.alb_enable_https
  certificate_arn       = var.alb_certificate_arn
  health_check_path     = "/health"
}

module "app" {
  source                = "./modules/app"
  project_name          = var.project_name
  instance_type         = var.instance_type
  private_subnet_ids    = module.vpc.private_subnet_ids
  app_security_group_id = module.security.app_sg_id
  target_group_arn      = module.alb.target_group_arn
  desired_capacity      = var.desired_capacity
  min_size              = var.min_size
  max_size              = var.max_size
}

module "codedeploy" {
  source             = "./modules/codedeploy"
  project_name       = var.project_name
  asg_name           = module.app.asg_name
  target_group_arn   = module.alb.target_group_arn
  target_group_name  = module.alb.target_group_name
}

module "monitoring" {
  source           = "./modules/monitoring"
  project_name     = var.project_name
  alb_arn_suffix   = module.alb.alb_arn_suffix
  target_group_arn = module.alb.target_group_arn
  asg_name         = module.app.asg_name
}