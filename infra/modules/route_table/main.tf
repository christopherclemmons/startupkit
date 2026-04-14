variable "vpc_id" {
  description = "VPC ID for the route table."
  type        = string
}

variable "name" {
  description = "Name tag for the route table."
  type        = string
}

variable "tags" {
  description = "Additional tags to apply."
  type        = map(string)
  default     = {}
}

variable "create_default_route" {
  description = "Whether to create a default route in this route table."
  type        = bool
  default     = false
}

variable "route_cidr_block" {
  description = "CIDR block for the route."
  type        = string
  default     = "0.0.0.0/0"
}

variable "gateway_id" {
  description = "Internet gateway ID for the route."
  type        = string
  default     = null
}

variable "nat_gateway_id" {
  description = "NAT gateway ID for the route."
  type        = string
  default     = null
}

resource "aws_route_table" "this" {
  vpc_id = var.vpc_id

  dynamic "route" {
    for_each = var.create_default_route ? [1] : []
    content {
      cidr_block     = var.route_cidr_block
      gateway_id     = var.gateway_id
      nat_gateway_id = var.nat_gateway_id
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

output "id" {
  description = "Route table ID."
  value       = aws_route_table.this.id
}
