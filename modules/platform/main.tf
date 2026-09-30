# Composes the full stack for one environment: network, EKS, Postgres,
# Valkey, and the IAM binding External Secrets uses to fetch DB credentials.

locals {
  name = "${var.project}-${var.environment}"
}

module "network" {
  source = "../network"

  name                     = local.name
  cidr_block               = var.vpc_cidr
  az_count                 = var.az_count
  single_nat_gateway       = var.single_nat_gateway
  cluster_name             = local.name
  flow_logs_retention_days = var.log_retention_days
}

module "eks" {
  source = "../eks"

  name                 = local.name
  kubernetes_version   = var.kubernetes_version
  subnet_ids           = module.network.private_subnet_ids
  public_access_cidrs  = var.eks_public_access_cidrs
  admin_principal_arns = var.eks_admin_principal_arns
  node_instance_types  = var.node_instance_types
  node_capacity_type   = var.node_capacity_type
  node_min_size        = var.node_min_size
  node_max_size        = var.node_max_size
  log_retention_days   = var.log_retention_days
}

module "database" {
  source = "../database"

  name                       = local.name
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.data_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]
  instance_class             = var.db_instance_class
  multi_az                   = var.db_multi_az
  backup_retention_days      = var.db_backup_retention_days
  deletion_protection        = var.db_deletion_protection
}

module "cache" {
  source = "../cache"

  name                       = local.name
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.data_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]
  node_type                  = var.cache_node_type
  node_count                 = var.cache_node_count
}

# External Secrets Operator reads only this environment's DB secret and
# renders the DATABASE_URL Secret the API consumes.
data "aws_iam_policy_document" "external_secrets" {
  statement {
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [module.database.master_user_secret_arn]
  }
}

module "external_secrets_identity" {
  source = "../pod-identity"

  name            = "${local.name}-external-secrets"
  cluster_name    = module.eks.cluster_name
  namespace       = "external-secrets"
  service_account = "external-secrets"
  policy_json     = data.aws_iam_policy_document.external_secrets.json
}
