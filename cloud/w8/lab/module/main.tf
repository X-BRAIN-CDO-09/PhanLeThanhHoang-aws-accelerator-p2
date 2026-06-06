# ===========================
# Module: VPC
# ===========================
module "vpc" {
  source                = "./vpc"
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidr    = var.public_subnet_cidr
  private_subnet_cidr_a = var.private_subnet_cidr_a
  private_subnet_cidr_b = var.private_subnet_cidr_b
}

# ===========================
# Module: Security Groups
# ===========================
module "security_groups" {
  source = "./sercurity_groups"
  vpc_id = module.vpc.vpc_id
}

# ===========================
# Module: RDS
# ===========================
module "rds" {
  source = "./rds"

  private_subnet_ids = module.vpc.private_subnet_ids
  instance_class     = var.db_instance_class
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  db_sg_id           = module.security_groups.db_sg_id
}

# ===========================
# Module: S3 (Static Assets)
# ===========================
module "s3" {
  source      = "./s3"
  bucket_name = var.bucket_name
}

# ===========================
# Module: EC2 (Web Server)
# ===========================
module "ec2" {
  source            = "./ec2"
  instance_type     = var.instance_type
  subnet_id         = module.vpc.public_subnet_id
  security_group_id = module.security_groups.web_sg_id
}
