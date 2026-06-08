# Lấy Default VPC hiện có
data "aws_vpc" "default" {
  default = true
}

# Lấy các Subnets của Default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "network" {
  source   = "./modules/network"
  vpc_id   = data.aws_vpc.default.id
  app_port = var.app_port
}

module "compute" {
  source                 = "./modules/compute"
  instance_type          = var.instance_type
  vpc_security_group_ids = [module.network.ec2_sg_id]
  app_port               = var.app_port
}

module "loadbalancing" {
  source      = "./modules/loadbalancing"
  vpc_id      = data.aws_vpc.default.id
  subnet_ids  = data.aws_subnets.default.ids
  alb_sg_id   = module.network.alb_sg_id
  instance_id = module.compute.instance_id
  app_port    = var.app_port
}
