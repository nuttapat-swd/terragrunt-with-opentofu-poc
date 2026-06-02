dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name           = "mock-cluster"
    cluster_endpoint       = "https://mock.eks.ap-southeast-7.amazonaws.com"
    cluster_ca_certificate = "bW9jaw=="
    oidc_provider_arn      = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.ap-southeast-7.amazonaws.com/id/MOCK"
    oidc_provider_url      = "https://oidc.eks.ap-southeast-7.amazonaws.com/id/MOCK"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "init", "plan"]
}

dependency "dns" {
  config_path = "../dns"

  mock_outputs = {
    zone_name = "dev.internal"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "init", "plan"]
}

locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env        = local.env_config.locals.env
  tags       = local.env_config.locals.tags
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

# root.hcl generates only the aws provider; helm provider must be generated here
generate "helm_provider" {
  path      = "helm_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "helm" {
      kubernetes {
        host                   = "${dependency.eks.outputs.cluster_endpoint}"
        cluster_ca_certificate = base64decode("${dependency.eks.outputs.cluster_ca_certificate}")
        exec {
          api_version = "client.authentication.k8s.io/v1beta1"
          command     = "aws"
          args        = ["eks", "get-token", "--cluster-name", "${dependency.eks.outputs.cluster_name}", "--region", "ap-southeast-7", "--profile", "poc"]
        }
      }
    }
  EOF
}

terraform {
  source = "../../../modules/external_dns"
}

inputs = {
  cluster_name      = dependency.eks.outputs.cluster_name
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
  oidc_provider_url = dependency.eks.outputs.oidc_provider_url
  domain_filters    = [dependency.dns.outputs.zone_name]
  aws_zone_type     = "private"

  tags = local.tags
}
