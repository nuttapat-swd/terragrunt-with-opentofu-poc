locals {
  common_tags = merge(var.tags, {
    Name      = var.name
    ManagedBy = "opentofu"
  })

  is_alb = var.lb_type == "application"
}

# ── Load Balancer ─────────────────────────────────────────────────────────────

resource "aws_lb" "this" {
  name               = var.name
  load_balancer_type = var.lb_type
  internal           = var.internal
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  # ALB only
  security_groups = local.is_alb ? var.security_group_ids : []

  tags = local.common_tags
}

# ── Target Groups ─────────────────────────────────────────────────────────────

resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name        = "${var.name}-${each.key}"
  port        = each.value.port
  protocol    = each.value.protocol
  target_type = each.value.target_type
  vpc_id      = var.vpc_id

  health_check {
    enabled             = each.value.health_check.enabled
    path                = (local.is_alb || each.value.target_type == "alb") ? each.value.health_check.path : null
    port                = each.value.health_check.port
    protocol            = coalesce(each.value.health_check.protocol, each.value.protocol)
    healthy_threshold   = each.value.health_check.healthy_threshold
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
    interval            = each.value.health_check.interval
    timeout             = local.is_alb ? each.value.health_check.timeout : null
  }

  tags = merge(local.common_tags, { Name = "${var.name}-${each.key}" })

  lifecycle {
    create_before_destroy = true
  }
}

# ── Listeners ─────────────────────────────────────────────────────────────────

resource "aws_lb_listener" "this" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol
  certificate_arn   = each.value.certificate_arn

  dynamic "default_action" {
    for_each = each.value.default_action_type == "forward" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this[each.value.default_target_group].arn
    }
  }

  dynamic "default_action" {
    for_each = each.value.default_action_type == "redirect" ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = each.value.redirect.port
        protocol    = each.value.redirect.protocol
        status_code = each.value.redirect.status_code
      }
    }
  }

  tags = merge(local.common_tags, { Name = "${var.name}-${each.key}" })
}
