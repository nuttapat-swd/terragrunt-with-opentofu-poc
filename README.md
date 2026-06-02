# terragrunt-with-opentofu-poc

OpenTofu + Terragrunt IaC for AWS (`ap-southeast-7`). Demonstrates the two-layer pattern: reusable modules wired to environment-specific units via Terragrunt.

## Prerequisites

| Tool | Purpose |
|------|---------|
| `opentofu` | IaC engine (replaces Terraform) |
| `terragrunt` | Orchestration layer |
| `direnv` | Loads `.envrc` → sets `AWS_PROFILE=poc` and `AWS_ACCOUNT_ID` |

```bash
direnv allow   # must run once after clone
```

---

## Project Structure

```
.
├── live/                          # Deployed environments (Terragrunt units)
│   ├── root.hcl                   # Global: S3 backend + provider generation
│   ├── bootstrap/                 # One-time: creates S3 tfstate bucket
│   └── dev/
│       ├── env.hcl                # Environment locals (name, shared tags)
│       ├── vpc/
│       │   └── terragrunt.hcl     # Unit → modules/vpc
│       ├── nlb/
│       │   └── terragrunt.hcl     # Unit → modules/load_balancer
│       ├── eks/
│       │   └── terragrunt.hcl     # Unit → modules/eks
│       ├── dns/
│       │   └── terragrunt.hcl     # Unit → modules/route53
│       ├── aws_load_balancer_controller/
│       │   └── terragrunt.hcl     # Unit → modules/aws_load_balancer_controller
│       └── external_dns/
│           └── terragrunt.hcl     # Unit → modules/external_dns
│
└── modules/                       # Reusable OpenTofu modules
    ├── vpc/
    ├── load_balancer/
    ├── eks/
    ├── route53/
    ├── aws_load_balancer_controller/
    └── external_dns/
```

### How the two layers fit together

```
live/dev/vpc/terragrunt.hcl
  │  include "root" → live/root.hcl          (backend + provider, auto-generated)
  │  read env.hcl   → live/dev/env.hcl       (env name, tags)
  └─ terraform.source → modules/vpc           (reusable module)
        └── inputs = { ... }                  (env-specific values)
```

---

## root.hcl — Global Config

`live/root.hcl` is included by every unit. It does two things:

**1. Auto-generates `backend.tf`** (S3 remote state, no DynamoDB needed):

```hcl
remote_state {
  backend = "s3"
  config = {
    bucket       = "self-tofu-tfstate-<account_id>"
    key          = "${path_relative_to_include()}/terraform.tfstate"
    region       = "ap-southeast-7"
    encrypt      = true
    use_lockfile = true   # native S3 lock
    profile      = "poc"
  }
}
```

State key mirrors the directory path, so each unit gets its own isolated state file.

**2. Auto-generates `provider.tf`**:

```hcl
generate "provider" {
  contents = <<-EOF
    provider "aws" {
      region  = "ap-southeast-7"
      profile = "poc"
    }
  EOF
}
```

> Do not commit generated `backend.tf` / `provider.tf` — they are in `.gitignore`.

---

## env.hcl — Environment Locals

Each environment has an `env.hcl` that defines shared locals read by every unit in that env:

```hcl
# live/dev/env.hcl
locals {
  env = "dev"
  tags = {
    Environment = local.env
    Project     = "self-tofu"
    ManagedBy   = "opentofu"
  }
}
```

Units read it via:

```hcl
locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env        = local.env_config.locals.env
  tags       = local.env_config.locals.tags
}
```

---

## Cross-Unit Dependencies

Units reference each other's outputs via `dependency` blocks — no manual output passing:

```hcl
# live/dev/eks/terragrunt.hcl
dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    private_subnet_ids = ["subnet-33333333", "subnet-44444444"]
  }
}

inputs = {
  subnet_ids = dependency.vpc.outputs.private_subnet_ids
}
```

`mock_outputs` lets `terragrunt plan` run before the dependency is applied.

Dependency graph for `dev`:

```
vpc
 ├─→ nlb
 ├─→ eks
 │     ├─→ aws_load_balancer_controller
 │     └─→ external_dns
 └─→ dns
```

---

## Common Commands

### Bootstrap (first time only)

```bash
cd live/bootstrap
tofu init
tofu apply -var-file=terraform.tfvars
```

### Single unit

```bash
cd live/dev/vpc
terragrunt init
terragrunt plan
terragrunt apply
terragrunt destroy
```

### Entire environment (respects dependency order)

```bash
cd live/dev
terragrunt run --all plan
terragrunt run --all apply
terragrunt run --all destroy
```

### Format

```bash
tofu fmt -recursive          # .tf files
terragrunt hclfmt            # .hcl files
```

---

## Adding a New Unit

1. Create `live/<env>/<unit>/terragrunt.hcl`
2. Include `root.hcl` and read `env.hcl`:

```hcl
locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env        = local.env_config.locals.env
  tags       = local.env_config.locals.tags
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/<module-name>"
}

inputs = {
  # env-specific values
}
```

3. Add `dependency` blocks if the unit needs outputs from other units.

## Adding a New Environment

1. Copy `live/dev/` → `live/<new-env>/`
2. Update `env.hcl` with the new env name
3. Adjust inputs per unit as needed

---

## Key Conventions

- All resources are tagged `ManagedBy = "opentofu"` via `local.tags` in each unit
- NAT Gateway is `false` by default to save cost; enable via `enable_nat_gateway = true` in the unit's inputs when private subnets need egress
- `load_balancer` module supports both ALB and NLB via `lb_type`; security groups attach only for `lb_type = "application"`
- EKS node groups use SPOT instances in dev; use `ON_DEMAND` for prod
