output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = [for subnet in values(module.public_subnets) : subnet.id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = [for subnet in values(module.private_subnets) : subnet.id]
}

output "app_security_group_id" {
  description = "Application security group ID."
  value       = module.app_security_group.id
}

output "nat_gateway_id" {
  description = "NAT gateway ID when enabled."
  value       = var.enable_nat_gateway ? module.nat_gateway[0].id : null
}
