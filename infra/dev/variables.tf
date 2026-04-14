variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name."
  type        = string
  default     = "app"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "default_route_cidr" {
  description = "CIDR block for default routes."
  type        = string
  default     = "0.0.0.0/0"
}

variable "public_ingress_cidrs" {
  description = "Ingress CIDRs for public HTTP/HTTPS access."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_ingress_cidrs" {
  description = "Ingress CIDRs for app ports."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT gateway and private default route."
  type        = bool
  default     = false
}


