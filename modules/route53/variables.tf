variable "zone_name" {
  description = "DNS zone name (e.g. example.com)"
  type        = string
}

variable "create_zone" {
  description = "Create a new hosted zone; false = look up existing zone by zone_name"
  type        = bool
  default     = true
}

variable "private_zone" {
  description = "Create a private hosted zone (requires vpc_ids)"
  type        = bool
  default     = false
}

variable "vpc_ids" {
  description = "VPC IDs to associate with a private hosted zone"
  type        = list(string)
  default     = []
}

variable "records" {
  description = "Map of DNS records to create"
  type = map(object({
    name = string       # relative name, e.g. "www" or "" for apex
    type = string       # A, AAAA, CNAME, MX, TXT, NS, SRV, …
    ttl  = optional(number, 300)

    # Non-alias records: provide values here
    values = optional(list(string), [])

    # Alias records: provide alias block instead of values + ttl
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool, true)
    }))
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
