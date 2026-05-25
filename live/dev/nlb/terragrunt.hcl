dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id             = "vpc-12345678"
    public_subnet_ids  = ["subnet-11111111", "subnet-22222222"]
    private_subnet_ids = ["subnet-33333333", "subnet-44444444"]
  }
}

locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env        = local.env_config.locals.env
  tags       = local.env_config.locals.tags
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/load_balancer"
}

inputs = {
    name = "nlb-${local.env}"
    lb_type = "network"
    internal = false
    vpc_id = dependency.vpc.outputs.vpc_id
    subnet_ids = dependency.vpc.outputs.public_subnet_ids
    enable_deletion_protection = false
    
    target_groups = {
      to-alb-https = {
        port        = 443
        protocol    = "TCP"
        target_type = "alb"
        health_check = {
          protocol = "HTTPS"
          path     = "/"
        }
      }
    }

    listeners = {
      https = {
        port                 = 443
        protocol             = "TCP"
        default_target_group = "to-alb-https"
      }
    }
}