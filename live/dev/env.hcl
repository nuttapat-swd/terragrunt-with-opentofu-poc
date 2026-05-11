locals {
  env = "dev"

  tags = {
    Environment = local.env
    Project     = "self-tofu"
    ManagedBy   = "opentofu"
  }
}
