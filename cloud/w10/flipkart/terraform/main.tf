# [w10-pm NEW] Created for w10_afternoon_secrets_supply_chain lab
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "network" {
  source   = "./modules/network"
  project  = var.project
  vpc_id   = data.aws_vpc.default.id
  app_port = var.app_port
}

module "compute" {
  source                 = "./modules/compute"
  project                = var.project
  instance_type          = var.instance_type
  vpc_security_group_ids = [module.network.ec2_sg_id]
  app_port               = var.app_port
  irsa_secret_arn        = module.secrets.db_secret_arn
}

module "loadbalancing" {
  source      = "./modules/loadbalancing"
  project     = var.project
  vpc_id      = data.aws_vpc.default.id
  subnet_ids  = data.aws_subnets.default.ids
  alb_sg_id   = module.network.alb_sg_id
  instance_id = module.compute.instance_id
  app_port    = var.app_port
}

module "secrets" {
  source              = "./modules/secrets"
  project             = var.project
  db_secret_name      = var.db_secret_name
  db_initial_password = var.db_initial_password
}
