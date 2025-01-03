terraform {
  backend "s3" {
    bucket         = "devops-terraform-state"
    key            = "eks/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}