terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.66"
    }
  }

  backend "s3" {
    bucket       = "salar24-links-tfstate"
    key          = "envs/prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "links"
      Environment = "prod"
      ManagedBy   = "terraform"
      Repository  = "github.com/Salar24/terraform-aws-platform"
    }
  }
}

# Prod optimises for availability: NAT per AZ, on-demand nodes across three
# AZs, Multi-AZ Postgres with deletion protection, and a Valkey replica.
module "platform" {
  source = "../../modules/platform"

  environment = "prod"
  vpc_cidr    = "10.20.0.0/16"

  single_nat_gateway = false

  eks_public_access_cidrs  = var.eks_public_access_cidrs
  eks_admin_principal_arns = var.eks_admin_principal_arns
  node_instance_types      = ["m6i.large"]
  node_capacity_type       = "ON_DEMAND"
  node_min_size            = 3
  node_max_size            = 9

  db_instance_class        = "db.m6g.large"
  db_multi_az              = true
  db_backup_retention_days = 14
  db_deletion_protection   = true

  cache_node_type  = "cache.m6g.large"
  cache_node_count = 2

  log_retention_days = 90
}
