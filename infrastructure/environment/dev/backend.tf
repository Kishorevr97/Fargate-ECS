terraform {
  backend "s3" {
    bucket         = "terraform-backend-statefil"  
    key            = "ecs/development/terraform.tfstate"
    region         = "eu-north-1"            
    encrypt        = true
  }
}
