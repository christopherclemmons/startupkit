output "api_alb_dns_name" {
  description = "Public DNS name for the API load balancer."
  value       = module.api_alb_router.dns_name
}

output "aws_region" {
  description = "AWS region used for this stack."
  value       = var.aws_region
}

output "frontend_url" {
  description = "Frontend entrypoint URL (CloudFront)."
  value       = "https://${module.frontend_hosting.domain_name}"
}

output "frontend_bucket_name" {
  description = "S3 bucket storing frontend static assets."
  value       = module.frontend_hosting.bucket_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for frontend cache invalidations."
  value       = module.frontend_hosting.cloudfront_distribution_id
}

output "backend_ecr_repository_url" {
  description = "Backend ECR repository URL."
  value       = module.backend_ecr_repository.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name for the dev stack."
  value       = module.ecs_cluster.name
}

output "database_endpoint" {
  description = "PostgreSQL endpoint for the dev RDS instance."
  value       = module.rds_postgres.address
}

output "database_name" {
  description = "PostgreSQL database name."
  value       = module.rds_postgres.db_name
}

output "database_tunnel_instance_id" {
  description = "EC2 instance ID for the SSM DB tunnel host."
  value       = aws_instance.db_tunnel_host.id
}

output "database_tunnel_instance_name" {
  description = "Name tag for the SSM DB tunnel host."
  value       = aws_instance.db_tunnel_host.tags.Name
}
