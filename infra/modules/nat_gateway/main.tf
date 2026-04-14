variable "allocation_id" {
  description = "Allocation ID for the NAT gateway elastic IP."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the NAT gateway will be created."
  type        = string
}

variable "name" {
  description = "Name tag for the NAT gateway."
  type        = string
}

variable "tags" {
  description = "Additional tags to apply."
  type        = map(string)
  default     = {}
}

resource "aws_nat_gateway" "this" {
  allocation_id = var.allocation_id
  subnet_id     = var.subnet_id

  tags = merge(var.tags, {
    Name = var.name
  })
}

output "id" {
  description = "NAT gateway ID."
  value       = aws_nat_gateway.this.id
}
