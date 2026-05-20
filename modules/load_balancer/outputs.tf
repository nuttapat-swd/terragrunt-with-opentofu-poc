output "lb_id" {
  description = "Load balancer ID"
  value       = aws_lb.this.id
}

output "lb_arn" {
  description = "Load balancer ARN"
  value       = aws_lb.this.arn
}

output "lb_dns_name" {
  description = "Load balancer DNS name"
  value       = aws_lb.this.dns_name
}

output "lb_zone_id" {
  description = "Load balancer canonical hosted zone ID (for Route53 alias)"
  value       = aws_lb.this.zone_id
}

output "target_group_arns" {
  description = "Map of target group ARNs keyed by name"
  value       = { for k, tg in aws_lb_target_group.this : k => tg.arn }
}

output "listener_arns" {
  description = "Map of listener ARNs keyed by name"
  value       = { for k, l in aws_lb_listener.this : k => l.arn }
}
