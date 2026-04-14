variable "vpc_id" {
  description = "VPC ID for the security group."
  type        = string
}

variable "name_prefix" {
  description = "Name prefix for the security group."
  type        = string
}

variable "description" {
  description = "Description for the security group."
  type        = string
  default     = "Managed by Terraform"
}

variable "ingress_rules" {
  description = "Ingress rules."
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

variable "egress_rules" {
  description = "Egress rules."
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

variable "tags" {
  description = "Additional tags to apply."
  type        = map(string)
  default     = {}
}

resource "aws_security_group" "this" {
  name_prefix = var.name_prefix
  description = var.description
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }

  tags = merge(var.tags, {
    Name = trimsuffix(var.name_prefix, "-")
  })
}

output "id" {
  description = "Security group ID."
  value       = aws_security_group.this.id
}

output "arn" {
  description = "Security group ARN."
  value       = aws_security_group.this.arn
}

output "name" {
  description = "Security group name."
  value       = aws_security_group.this.name
}
