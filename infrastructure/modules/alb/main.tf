resource "aws_lb" "main" {
  name               = var.lb_name
  internal           = false
  load_balancer_type = "application"
  security_groups = var.security_groups
  subnets           = var.public_subnet_id
}
