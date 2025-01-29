aws_region = "eu-north-1"

vpc_cidr        = "10.0.0.0/16"
vpc_name        = "dev-vpc"
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
azs             = ["eu-north-1a", "eu-north-1b"]

cluster_name = "dev-cluster"
repo_name    = "dev-repo"

lb_name         = "dev-alb"
security_groups  = ["sg-xxxxxx"]
public_subnets_ids =  ["10.0.1.0/24", "10.0.2.0/24"]
