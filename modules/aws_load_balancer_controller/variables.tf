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

variable "vpc_id" {
  description = "VPC ID where the EKS cluster runs"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace to deploy the controller"
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Name of the Kubernetes ServiceAccount for the controller"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "chart_version" {
  description = "Helm chart version for aws-load-balancer-controller"
  type        = string
  default     = "3.3.0"
}

variable "tags" {
  description = "Additional tags applied to IAM resources"
  type        = map(string)
  default     = {}
}
