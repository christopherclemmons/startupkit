variable "cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name tag for the VPC."
  type        = string
}

variable "tags" {
  description = "Additional tags to apply."
  type        = map(string)
  default     = {}
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(var.tags, {
    Name = var.name
  })
}

output "id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "arn" {
  description = "VPC ARN."
  value       = aws_vpc.this.arn
}

output "cidr_block" {
  description = "VPC CIDR block."
  value       = aws_vpc.this.cidr_block
}
