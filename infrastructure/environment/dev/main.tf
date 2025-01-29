provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source          = "../../modules/vpc"
  vpc_cidr        = "10.0.0.0/16"
  vpc_name        = "dev-vpc"
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
  azs             = ["eu-north-1a", "eu-north-1b"]
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
  public_subnet_ids = module.vpc.public_subnets
  security_groups   = [module.iam.ecs_sg_id]
}


