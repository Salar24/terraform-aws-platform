output "vpc_id" {
  value = module.network.vpc_id
}

output "nat_public_ips" {
  value = module.network.nat_public_ips
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name}"
}

output "redis_url" {
  description = "Value for external.redisURL in k8s-platform's environment values."
  value       = module.cache.redis_url
}

output "database_address" {
  value = module.database.address
}

output "database_secret_arn" {
  description = "Secrets Manager ARN for the ExternalSecret that builds DATABASE_URL."
  value       = module.database.master_user_secret_arn
}

output "external_secrets_role_arn" {
  value = module.external_secrets_identity.role_arn
}
