provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = var.tags
}

# Use local-exec to check if log group exists and store result
resource "null_resource" "check_log_group" {
  provisioner "local-exec" {
    command = <<EOT
      exists=$(aws logs describe-log-groups --log-group-name-prefix "/aws/eks/${var.cluster_name}/cluster" --query 'logGroups[0].logGroupName' --output text)
      if [ "$exists" != "None" ]; then
        echo "true" > log_group_exists.txt
      else
        echo "false" > log_group_exists.txt
      fi
    EOT
  }
}

# Read the result file
data "local_file" "log_group_exists" {
  depends_on = [null_resource.check_log_group]
  filename   = "log_group_exists.txt"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  # Use the result to conditionally create log group
  create_cloudwatch_log_group = trimspace(data.local_file.log_group_exists.content) == "false"

  eks_managed_node_groups = {
    default = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
    }
  }

  tags = var.tags
}