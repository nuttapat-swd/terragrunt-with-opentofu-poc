output "role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller (IRSA)"
  value       = aws_iam_role.lbc.arn
}

output "role_name" {
  description = "IAM role name for AWS Load Balancer Controller"
  value       = aws_iam_role.lbc.name
}
