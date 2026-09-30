output "platform" {
  description = "Values to wire into k8s-platform (redis_url, database_secret_arn, ...)."
  value       = module.platform
}
