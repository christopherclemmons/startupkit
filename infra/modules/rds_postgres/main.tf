variable "identifier" {
  description = "RDS instance identifier."
  type        = string
}

variable "db_name" {
  description = "Application database name."
  type        = string
}

variable "username" {
  description = "Master username."
  type        = string
}

variable "password" {
  description = "Master password."
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the database subnet group."
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "Security groups for the RDS instance."
  type        = list(string)
}

variable "availability_zone" {
  description = "Availability zone for single-AZ deployments."
  type        = string
}

variable "allocated_storage" {
  description = "Initial allocated storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum autoscaled storage in GiB."
  type        = number
  default     = 100
}

variable "backup_retention_period" {
  description = "Backup retention period in days."
  type        = number
  default     = 1
}

variable "skip_final_snapshot" {
  description = "Whether to skip final snapshot on deletion."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Whether to protect the instance from deletion."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply."
  type        = map(string)
  default     = {}
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnets"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_db_instance" "this" {
  identifier                 = var.identifier
  allocated_storage          = var.allocated_storage
  max_allocated_storage      = var.max_allocated_storage
  engine                     = "postgres"
  instance_class             = var.instance_class
  db_name                    = var.db_name
  username                   = var.username
  password                   = var.password
  db_subnet_group_name       = aws_db_subnet_group.this.name
  vpc_security_group_ids     = var.vpc_security_group_ids
  publicly_accessible        = false
  multi_az                   = false
  availability_zone          = var.availability_zone
  backup_retention_period    = var.backup_retention_period
  skip_final_snapshot        = var.skip_final_snapshot
  deletion_protection        = var.deletion_protection
  apply_immediately          = true
  auto_minor_version_upgrade = true
  storage_encrypted          = true
  tags                       = var.tags
}

output "address" {
  description = "Database endpoint address."
  value       = aws_db_instance.this.address
}

output "db_name" {
  description = "Database name."
  value       = aws_db_instance.this.db_name
}

output "arn" {
  description = "RDS instance ARN."
  value       = aws_db_instance.this.arn
}
