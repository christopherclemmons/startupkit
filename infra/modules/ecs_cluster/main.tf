variable "name" {
  description = "Name of the ECS cluster."
  type        = string
}

variable "tags" {
  description = "Additional tags to apply."
  type        = map(string)
  default     = {}
}

resource "aws_ecs_cluster" "this" {
  name = var.name
  tags = var.tags
}

output "id" {
  description = "ECS cluster ID."
  value       = aws_ecs_cluster.this.id
}

output "arn" {
  description = "ECS cluster ARN."
  value       = aws_ecs_cluster.this.arn
}

output "name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}
