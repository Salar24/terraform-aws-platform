output "primary_endpoint" {
  value = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "redis_url" {
  description = "TLS connection URL for the API's REDIS_URL."
  value       = "rediss://${aws_elasticache_replication_group.this.primary_endpoint_address}:6379/0"
}

output "security_group_id" {
  value = aws_security_group.this.id
}
