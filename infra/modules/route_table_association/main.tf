variable "subnet_id" {
  description = "Subnet ID to associate."
  type        = string
}

variable "route_table_id" {
  description = "Route table ID for the association."
  type        = string
}

resource "aws_route_table_association" "this" {
  subnet_id      = var.subnet_id
  route_table_id = var.route_table_id
}

output "id" {
  description = "Route table association ID."
  value       = aws_route_table_association.this.id
}
