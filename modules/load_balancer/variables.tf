variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "lb_type" {
  description = "Load balancer type: application (ALB) or network (NLB)"
  type        = string
  validation {
    condition     = contains(["application", "network"], var.lb_type)
    error_message = "lb_type must be 'application' or 'network'."
  }
}

variable "internal" {
  description = "Internal (true) or internet-facing (false)"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs to attach to the LB"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs — ALB only"
  type        = list(string)
  default     = []
}

variable "enable_deletion_protection" {
  description = "Prevent accidental deletion"
  type        = bool
  default     = false
}

variable "target_groups" {
  description = "Map of target group configs"
  type = map(object({
    port             = number
    protocol         = string # HTTP, HTTPS, TCP, TLS, UDP
    target_type      = string # instance, ip, lambda
    health_check = optional(object({
      enabled             = optional(bool, true)
      path                = optional(string, "/")
      port                = optional(string, "traffic-port")
      protocol            = optional(string)
      healthy_threshold   = optional(number, 3)
      unhealthy_threshold = optional(number, 3)
      interval            = optional(number, 30)
      timeout             = optional(number, 10)
    }), {})
  }))
  default = {}
}

variable "listeners" {
  description = "Map of listener configs"
  type = map(object({
    port              = number
    protocol          = string # HTTP, HTTPS, TCP, TLS, UDP
    certificate_arn   = optional(string)
    default_target_group = string # key from var.target_groups
    # ALB only: action type override
    default_action_type = optional(string, "forward")
    # ALB redirect (when default_action_type = "redirect")
    redirect = optional(object({
      port        = optional(string, "443")
      protocol    = optional(string, "HTTPS")
      status_code = optional(string, "HTTP_301")
    }))
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
