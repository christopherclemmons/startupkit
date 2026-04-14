variable "backend_image_tag" {
  description = "Container image tag to deploy for the backend service."
  type        = string
  default     = "latest"
}

variable "backend_task_cpu" {
  description = "CPU units for the backend ECS task."
  type        = number
  default     = 256
}

variable "backend_task_memory" {
  description = "Memory (MiB) for the backend ECS task."
  type        = number
  default     = 512
}

# Security hardening controls for the backend runtime. These are intentionally
# explicit Terraform variables so production posture can be enabled via apply.
variable "security_require_authentication" {
  description = "Whether the backend API requires JWT authentication."
  type        = bool
  default     = false
}

variable "security_enable_https_redirection" {
  description = "Whether the backend API enforces HTTPS redirection."
  type        = bool
  default     = false
}

variable "security_jwt_authority" {
  description = "OIDC authority/issuer URL used for JWT validation when authentication is enabled."
  type        = string
  default     = ""
}

variable "security_jwt_audience" {
  description = "Expected JWT audience for API tokens when authentication is enabled."
  type        = string
  default     = ""
}

variable "security_rate_limit_permit_limit" {
  description = "Maximum API requests per rate-limit window per client IP."
  type        = number
  default     = 120
}

variable "security_rate_limit_window_seconds" {
  description = "Rate-limit window duration in seconds."
  type        = number
  default     = 60
}

variable "service_desired_count" {
  description = "Desired task count for the backend ECS service in dev. Keep this at 0 until the backend image is pushed to ECR."
  type        = number
  default     = 0
}

variable "alb_ingress_cidrs" {
  description = "CIDRs allowed to access the public ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "db_instance_class" {
  description = "RDS PostgreSQL instance class for the application database."
  type        = string
  default     = "db.t4g.micro"
}

# Security hardening defaults for data durability and safe teardown behavior.
variable "db_backup_retention_period" {
  description = "RDS backup retention period in days."
  type        = number
  default     = 7
}

variable "db_skip_final_snapshot" {
  description = "Whether to skip final snapshot when destroying DB."
  type        = bool
  default     = false
}

variable "db_deletion_protection" {
  description = "Whether to enable RDS deletion protection."
  type        = bool
  default     = true
}

variable "db_tunnel_instance_type" {
  description = "EC2 instance type for the SSM-only DB tunnel host."
  type        = string
  default     = "t3.nano"
}

variable "db_name" {
  description = "Database name for the application."
  type        = string
  default     = "app"
}

variable "db_username" {
  description = "Master username for the PostgreSQL instance."
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Master password for the PostgreSQL instance."
  type        = string
  sensitive   = true
}


