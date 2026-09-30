terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.66"
    }
  }

  # State bucket is created by ../../bootstrap. S3 native locking
  # (use_lockfile) replaces the old DynamoDB lock table.
  backend "s3" {
    bucket       = "salar24-links-tfstate"
    key          = "envs/dev/terraform.tfstate"
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
      Environment = "dev"
      ManagedBy   = "terraform"
      Repository  = "github.com/Salar24/terraform-aws-platform"
    }
  }
}

# Dev optimises for cost: one NAT gateway, Spot nodes, single-AZ database
# and cache, and no deletion protection so the stack can be torn down.
module "platform" {
  source = "../../modules/platform"

  environment = "dev"
  vpc_cidr    = "10.10.0.0/16"

  single_nat_gateway = true

  eks_public_access_cidrs  = var.eks_public_access_cidrs
  eks_admin_principal_arns = var.eks_admin_principal_arns
  node_instance_types      = ["t3.medium", "t3a.medium"]
  node_capacity_type       = "SPOT"
  node_min_size            = 2
  node_max_size            = 3

  db_instance_class        = "db.t4g.micro"
  db_multi_az              = false
  db_backup_retention_days = 1
  db_deletion_protection   = false

  cache_node_type  = "cache.t4g.micro"
  cache_node_count = 1

  log_retention_days = 7
}
