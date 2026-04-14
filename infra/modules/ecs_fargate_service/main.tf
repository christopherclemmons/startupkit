variable "family" {
  description = "Task definition family name."
  type        = string
}

variable "service_name" {
  description = "ECS service name."
  type        = string
}

variable "cluster_id" {
  description = "ECS cluster ID."
  type        = string
}

variable "execution_role_arn" {
  description = "IAM role ARN used by ECS agent for pulls/logging."
  type        = string
}

variable "task_role_arn" {
  description = "IAM role ARN assigned to the running container task."
  type        = string
}

variable "cpu" {
  description = "Task CPU units."
  type        = number
}

variable "memory" {
  description = "Task memory (MiB)."
  type        = number
}

variable "container_name" {
  description = "Container name inside the task definition."
  type        = string
}

variable "image" {
  description = "Full container image reference."
  type        = string
}

variable "container_port" {
  description = "Container port for traffic."
  type        = number
}

variable "environment" {
  description = "Container environment variables."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "log_group_name" {
  description = "CloudWatch log group name."
  type        = string
}

variable "aws_region" {
  description = "AWS region for CloudWatch logging."
  type        = string
}

variable "desired_count" {
  description = "Desired number of running tasks."
  type        = number
}

variable "subnets" {
  description = "Subnets to place ECS tasks in."
  type        = list(string)
}

variable "security_groups" {
  description = "Security groups for ECS tasks."
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Whether tasks should receive public IPs."
  type        = bool
  default     = false
}

variable "target_group_arn" {
  description = "Target group ARN to register this service with."
  type        = string
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percent during deployment."
  type        = number
  default     = 50
}

variable "deployment_maximum_percent" {
  description = "Maximum percent during deployment."
  type        = number
  default     = 200
}

variable "force_new_deployment" {
  description = "Force a new deployment on each apply."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply."
  type        = map(string)
  default     = {}
}

resource "aws_cloudwatch_log_group" "this" {
  name              = var.log_group_name
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.family
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = var.environment
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = var.tags
}

resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  force_new_deployment               = var.force_new_deployment

  network_configuration {
    subnets          = var.subnets
    security_groups  = var.security_groups
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  tags = var.tags
}

output "task_definition_arn" {
  description = "Task definition ARN."
  value       = aws_ecs_task_definition.this.arn
}

output "service_id" {
  description = "ECS service ID."
  value       = aws_ecs_service.this.id
}
