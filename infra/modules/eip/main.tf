variable "domain" {
  description = "Domain for the EIP allocation."
  type        = string
  default     = "vpc"
}

variable "name" {
  description = "Name tag for the elastic IP."
  type        = string
}

variable "tags" {
  description = "Additional tags to apply."
  type        = map(string)
  default     = {}
}

resource "aws_eip" "this" {
  domain = var.domain

  tags = merge(var.tags, {
    Name = var.name
  })
}

output "id" {
  description = "Elastic IP allocation ID."
  value       = aws_eip.this.id
}

output "allocation_id" {
  description = "Elastic IP allocation ID."
  value       = aws_eip.this.id
}

output "public_ip" {
  description = "Elastic IP public address."
  value       = aws_eip.this.public_ip
}
