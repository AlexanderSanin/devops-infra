provider "aws" {
  region = var.region
}

# Remove this duplicate block from main.tf
# terraform {
#   backend "s3" {
#     bucket = "devops-terraform-state-sanin"
#     key    = "eks/terraform.tfstate"
#     region = "eu-west-1"
#   }
# }

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = var.tags
}