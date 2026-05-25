variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.32"
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS control plane (private recommended)"
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = false
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "node_groups" {
  description = "Map of managed node group configs"
  type = map(object({
    subnet_ids     = list(string)
    instance_types = optional(list(string), ["t3.medium"])
    capacity_type  = optional(string, "ON_DEMAND") # ON_DEMAND or SPOT
    disk_size      = optional(number, 20)

    desired_size = optional(number, 1)
    min_size     = optional(number, 1)
    max_size     = optional(number, 3)

    labels = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string # NO_SCHEDULE, NO_EXECUTE, PREFER_NO_SCHEDULE
    })), [])
  }))
  default = {}
}

variable "cluster_addons" {
  description = "Map of EKS add-on configs (coredns, kube-proxy, vpc-cni, aws-ebs-csi-driver)"
  type = map(object({
    addon_version               = optional(string)
    resolve_conflicts_on_create = optional(string, "OVERWRITE")
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
  }))
  default = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
