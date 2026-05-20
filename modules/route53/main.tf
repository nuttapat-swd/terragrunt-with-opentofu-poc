locals {
  common_tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })

  zone_id = var.create_zone ? aws_route53_zone.this[0].zone_id : data.aws_route53_zone.this[0].zone_id
}

# ── Hosted Zone ───────────────────────────────────────────────────────────────

resource "aws_route53_zone" "this" {
  count = var.create_zone ? 1 : 0

  name = var.zone_name

  dynamic "vpc" {
    for_each = var.private_zone ? var.vpc_ids : []
    content {
      vpc_id = vpc.value
    }
  }

  tags = merge(local.common_tags, { Name = var.zone_name })
}

data "aws_route53_zone" "this" {
  count = var.create_zone ? 0 : 1

  name         = var.zone_name
  private_zone = var.private_zone
}

# ── DNS Records ───────────────────────────────────────────────────────────────

resource "aws_route53_record" "this" {
  for_each = var.records

  zone_id = local.zone_id
  name    = each.value.name == "" ? var.zone_name : "${each.value.name}.${var.zone_name}"
  type    = each.value.type

  # TTL is ignored for alias records; OpenTofu accepts null here
  ttl = each.value.alias == null ? each.value.ttl : null

  # Non-alias values
  records = each.value.alias == null ? each.value.values : null

  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }
}
