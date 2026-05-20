output "zone_id" {
  description = "Hosted zone ID"
  value       = local.zone_id
}

output "zone_name" {
  description = "Hosted zone name"
  value       = var.zone_name
}

output "name_servers" {
  description = "Name servers for the hosted zone (only set when create_zone = true)"
  value       = var.create_zone ? aws_route53_zone.this[0].name_servers : []
}

output "record_fqdns" {
  description = "Map of record FQDNs keyed by record key"
  value       = { for k, r in aws_route53_record.this : k => r.fqdn }
}
