variable "vpc_id" {
  description = "VPC ID for the internet gateway."
  type        = string
}

variable "name" {
  description = "Name tag for the internet gateway."
  type        = string
}

variable "tags" {
  description = "Additional tags to apply."
  type        = map(string)
  default     = {}
}

resource "aws_internet_gateway" "this" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = var.name
  })
}

output "id" {
  description = "Internet gateway ID."
  value       = aws_internet_gateway.this.id
}

output "arn" {
  description = "Internet gateway ARN."
  value       = aws_internet_gateway.this.arn
}
