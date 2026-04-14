data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }

  public_subnet_configs = {
    for idx, cidr in var.public_subnet_cidrs :
    tostring(idx) => {
      cidr_block        = cidr
      availability_zone = data.aws_availability_zones.available.names[idx]
    }
  }

  private_subnet_configs = {
    for idx, cidr in var.private_subnet_cidrs :
    tostring(idx) => {
      cidr_block        = cidr
      availability_zone = data.aws_availability_zones.available.names[idx]
    }
  }

  app_ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = var.public_ingress_cidrs
      description = "HTTP"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.public_ingress_cidrs
      description = "HTTPS"
    },
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = var.app_ingress_cidrs
      description = "Frontend app port"
    },
    {
      from_port   = 5000
      to_port     = 5000
      protocol    = "tcp"
      cidr_blocks = var.app_ingress_cidrs
      description = "Backend API port"
    }
  ]

  app_egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all egress"
    }
  ]
}

module "vpc" {
  source = "../modules/vpc"

  cidr_block = var.vpc_cidr
  name       = "${var.project_name}-vpc"
  tags       = local.common_tags
}

module "public_subnets" {
  source   = "../modules/subnet"
  for_each = local.public_subnet_configs

  vpc_id                  = module.vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true
  name                    = "${var.project_name}-public-subnet-${tonumber(each.key) + 1}"
  tags                    = local.common_tags
}

module "private_subnets" {
  source   = "../modules/subnet"
  for_each = local.private_subnet_configs

  vpc_id                  = module.vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false
  name                    = "${var.project_name}-private-subnet-${tonumber(each.key) + 1}"
  tags                    = local.common_tags
}

module "internet_gateway" {
  source = "../modules/internet_gateway"

  vpc_id = module.vpc.id
  name   = "${var.project_name}-igw"
  tags   = local.common_tags
}

module "public_route_table" {
  source = "../modules/route_table"

  vpc_id               = module.vpc.id
  name                 = "${var.project_name}-public-rt"
  create_default_route = true
  route_cidr_block     = var.default_route_cidr
  gateway_id           = module.internet_gateway.id
  tags                 = local.common_tags
}

module "public_route_table_associations" {
  source   = "../modules/route_table_association"
  for_each = module.public_subnets

  subnet_id      = each.value.id
  route_table_id = module.public_route_table.id
}

module "nat_eip" {
  source = "../modules/eip"
  count  = var.enable_nat_gateway ? 1 : 0

  name = "${var.project_name}-nat-eip"
  tags = local.common_tags
}

module "nat_gateway" {
  source = "../modules/nat_gateway"
  count  = var.enable_nat_gateway ? 1 : 0

  allocation_id = module.nat_eip[0].allocation_id
  subnet_id     = module.public_subnets["0"].id
  name          = "${var.project_name}-nat-gateway"
  tags          = local.common_tags
}

module "private_route_table" {
  source = "../modules/route_table"
  count  = var.enable_nat_gateway ? 1 : 0

  vpc_id               = module.vpc.id
  name                 = "${var.project_name}-private-rt"
  create_default_route = true
  route_cidr_block     = var.default_route_cidr
  nat_gateway_id       = module.nat_gateway[0].id
  tags                 = local.common_tags
}

module "private_route_table_associations" {
  source   = "../modules/route_table_association"
  for_each = var.enable_nat_gateway ? module.private_subnets : {}

  subnet_id      = each.value.id
  route_table_id = module.private_route_table[0].id
}

module "app_security_group" {
  source = "../modules/security_group"

  vpc_id        = module.vpc.id
  name_prefix   = "${var.project_name}-app-"
  description   = "Security group for application traffic."
  ingress_rules = local.app_ingress_rules
  egress_rules  = local.app_egress_rules
  tags          = local.common_tags
}
