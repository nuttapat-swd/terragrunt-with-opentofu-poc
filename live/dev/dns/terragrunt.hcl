dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id             = "vpc-12345678"
    public_subnet_ids  = ["subnet-11111111", "subnet-22222222"]
    private_subnet_ids = ["subnet-33333333", "subnet-44444444"]
  }
}

# dependency "nlb" {
#   config_path = "../nlb"
# }

locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env        = local.env_config.locals.env
  tags       = local.env_config.locals.tags
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/route53"
}

inputs = {
  zone_name    = "${local.env}.internal"
  create_zone  = true
  private_zone = true
  vpc_ids      = [dependency.vpc.outputs.vpc_id]

  records = {
    # app = {
    #   name  = "app"
    #   type  = "A"
    #   alias = {
    #     name                   = dependency.nlb.outputs.lb_dns_name
    #     zone_id                = dependency.nlb.outputs.lb_zone_id
    #     evaluate_target_health = true
    #   }
    # }
  }

  tags = local.tags
}
