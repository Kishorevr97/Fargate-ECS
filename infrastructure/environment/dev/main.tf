provider "aws" {
  aws_region = var.aws_region
}

module "vpc" {
  source          = "../../modules/vpc"
  vpc_cidr        = var.vpc_cidr
  vpc_name        = "dev-vpc"
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  azs             = var.azs
}

module "ecs" {
  source = "../../modules/ecs"
  cluster_name = "dev-cluster"
}

module "iam" {
  source = "../../modules/iam"
  vpc_id = module.vpc.vpc_id
}

module "ecr" {
  source = "../../modules/ecr"
  repo_name = "dev-repo"
}


module "alb" {
  source            = "../../modules/alb"
  lb_name           = "dev-alb"
  public_subnet_ids = var.public_subnet_ids
  security_groups   = [module.iam.ecs_sg_id]
}


