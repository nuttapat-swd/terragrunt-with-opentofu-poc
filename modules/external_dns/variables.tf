variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN (from EKS module output)"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL including https:// prefix (from EKS module output)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace to deploy external-dns"
  type        = string
  default     = "external-dns"
}

variable "service_account_name" {
  description = "Kubernetes ServiceAccount name for external-dns"
  type        = string
  default     = "external-dns"
}

variable "chart_version" {
  description = "Helm chart version for external-dns"
  type        = string
  default     = "1.21.1"
}

variable "domain_filters" {
  description = "Limit possible target zones by domain suffixes; empty list means all zones"
  type        = list(string)
  default     = []
}

variable "policy" {
  description = "DNS record sync policy: create-only, sync, or upsert-only"
  type        = string
  default     = "upsert-only"
}

variable "txt_owner_id" {
  description = "TXT registry owner ID to distinguish this external-dns instance; defaults to cluster_name"
  type        = string
  default     = null
}

variable "aws_zone_type" {
  description = "AWS Route53 zone type to target: public, private, or empty string for both"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags applied to IAM resources"
  type        = map(string)
  default     = {}
}
