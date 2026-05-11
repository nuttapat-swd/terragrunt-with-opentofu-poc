locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env        = local.env_config.locals.env
  tags       = local.env_config.locals.tags
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/vpc"
}

inputs = {
  name = local.env

  cidr = "10.0.0.0/16"

  azs = [
    "ap-southeast-7a",
    "ap-southeast-7b",
    # "ap-southeast-7c",
  ]

  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    # "10.0.3.0/24",
  ]

  private_subnets = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    # "10.0.103.0/24",
  ]

  enable_nat_gateway = false
  # single_nat_gateway = false
  enable_s3_endpoint = true

  tags = local.tags
}
