locals {
  account_id = get_env("AWS_ACCOUNT_ID")
  region     = "ap-southeast-7"
  project    = "self-tofu"
}

# Auto-generate backend.tf in each unit
remote_state {
  backend = "s3"
  config = {
    bucket       = "${local.project}-tfstate-${local.account_id}"
    key          = "${path_relative_to_include()}/terraform.tfstate"
    region       = local.region
    encrypt      = true
    use_lockfile = true
    profile      = "poc"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Auto-generate provider.tf in each unit
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region  = "${local.region}"
      profile = "poc"
    }
  EOF
}
