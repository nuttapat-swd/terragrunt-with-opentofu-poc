output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = aws_eks_cluster.this.version
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN (for IRSA)"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL (for IRSA)"
  value       = aws_iam_openid_connect_provider.eks.url
}

output "node_role_arn" {
  description = "IAM role ARN shared by all managed node groups"
  value       = aws_iam_role.node.arn
}

output "node_group_ids" {
  description = "Map of node group IDs keyed by node group key"
  value       = { for k, ng in aws_eks_node_group.this : k => ng.id }
}
