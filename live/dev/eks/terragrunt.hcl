dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
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
  source = "../../../modules/eks"
}

inputs = {
  cluster_name = "${local.env}-cluster"

  kubernetes_version = "1.32"

  subnet_ids = dependency.vpc.outputs.private_subnet_ids

  # Public access on for dev — easier kubectl from local; disable for prod
  endpoint_public_access  = true
  endpoint_private_access = true

  node_groups = {
    main = {
      subnet_ids = dependency.vpc.outputs.private_subnet_ids

      # Multiple instance families improves SPOT availability
      instance_types = ["c7i-flex.large"]
      capacity_type  = "SPOT"

      desired_size = 1
      min_size     = 1
      max_size     = 1
    }
  }

  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
    # Enables EBS PersistentVolumes; node role has EBS permissions via AmazonEKSWorkerNodePolicy
    # For prod, replace with IRSA service account
    # aws-ebs-csi-driver = {}
  }

  tags = local.tags
}
