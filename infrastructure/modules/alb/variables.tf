variable "lb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
}


variable "security_groups" {
  description = "List of security group IDs for the ALB"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where the ALB should be deployed"
  type        = list(string)
}
