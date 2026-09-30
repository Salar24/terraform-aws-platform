output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  value = try(aws_eks_cluster.this.certificate_authority[0].data, null)
}

output "cluster_security_group_id" {
  description = "Security group EKS attaches to the control plane and managed nodes; data stores allow ingress from it."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "node_role_arn" {
  value = aws_iam_role.node.arn
}
