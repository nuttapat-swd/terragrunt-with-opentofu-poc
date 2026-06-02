output "role_arn" {
  description = "IAM role ARN for external-dns (IRSA)"
  value       = aws_iam_role.external_dns.arn
}

output "role_name" {
  description = "IAM role name for external-dns"
  value       = aws_iam_role.external_dns.name
}
