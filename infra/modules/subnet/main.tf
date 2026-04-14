variable "vpc_id" {
  description = "VPC ID for the subnet."
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the subnet."
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for the subnet."
  type        = string
}

variable "map_public_ip_on_launch" {
  description = "Map public IP on instance launch."
  type        = bool
  default     = false
}

variable "name" {
  description = "Name tag for the subnet."
  type        = string
}

variable "tags" {
  description = "Additional tags to apply."
  type        = map(string)
  default     = {}
}

resource "aws_subnet" "this" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.cidr_block
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(var.tags, {
    Name = var.name
  })
}

output "id" {
  description = "Subnet ID."
  value       = aws_subnet.this.id
}

output "arn" {
  description = "Subnet ARN."
  value       = aws_subnet.this.arn
}

output "cidr_block" {
  description = "Subnet CIDR block."
  value       = aws_subnet.this.cidr_block
}
