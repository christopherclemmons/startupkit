locals {
  public_subnet_ids  = [for key in sort(keys(module.public_subnets)) : module.public_subnets[key].id]
  private_subnet_ids = [for key in sort(keys(module.private_subnets)) : module.private_subnets[key].id]

  ecs_service_subnet_ids = [local.public_subnet_ids[0]]

  backend_ecr_repo_name = "${var.project_name}-${var.environment}-backend"
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "${var.project_name}-${var.environment}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.project_name}-${var.environment}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role" "db_tunnel_host_role" {
  name               = "${var.project_name}-${var.environment}-db-tunnel-host-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "db_tunnel_host_ssm_core" {
  # Security hardening: this allows Session Manager access without opening SSH.
  role       = aws_iam_role.db_tunnel_host_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "db_tunnel_host" {
  name = "${var.project_name}-${var.environment}-db-tunnel-host-profile"
  role = aws_iam_role.db_tunnel_host_role.name
}

module "backend_ecr_repository" {
  source = "../modules/ecr_repository"

  name = local.backend_ecr_repo_name
  tags = local.common_tags
}

module "ecs_cluster" {
  source = "../modules/ecs_cluster"

  name = "${var.project_name}-${var.environment}-cluster"
  tags = local.common_tags
}

resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  description = "Ingress security group for the application ALB."
  vpc_id      = module.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidrs
    description = "Public HTTP ingress"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  })
}

resource "aws_security_group" "backend_service" {
  name_prefix = "${var.project_name}-backend-"
  description = "Security group for backend ECS tasks."
  vpc_id      = module.vpc.id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Allow ALB to reach backend tasks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-backend-sg"
  })
}

resource "aws_security_group" "database" {
  name_prefix = "${var.project_name}-db-"
  description = "Security group for PostgreSQL database."
  vpc_id      = module.vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_service.id]
    description     = "Allow backend tasks to reach PostgreSQL"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-db-sg"
  })
}

resource "aws_security_group" "db_tunnel_host" {
  name_prefix = "${var.project_name}-db-tunnel-"
  description = "Security group for SSM-only DB tunnel host."
  vpc_id      = module.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound traffic for SSM and DB connections"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-db-tunnel-host-sg"
  })
}

resource "aws_security_group_rule" "database_from_tunnel_host" {
  # Security hardening: permit DB access from the SSM tunnel host only (no public DB ingress).
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.database.id
  source_security_group_id = aws_security_group.db_tunnel_host.id
  description              = "Allow SSM tunnel host to reach PostgreSQL"
}

data "aws_ssm_parameter" "amazon_linux_2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "db_tunnel_host" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2023_ami.value
  instance_type               = var.db_tunnel_instance_type
  subnet_id                   = local.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.db_tunnel_host.id]
  iam_instance_profile        = aws_iam_instance_profile.db_tunnel_host.name
  associate_public_ip_address = true

  metadata_options {
    # Security hardening: require IMDSv2 tokens to reduce metadata credential abuse risk.
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-db-tunnel-host"
  })

  depends_on = [
    aws_iam_role_policy_attachment.db_tunnel_host_ssm_core
  ]
}

module "api_alb_router" {
  source = "../modules/alb_api_router"

  name_prefix          = "${var.project_name}-${var.environment}"
  vpc_id               = module.vpc.id
  subnet_ids           = local.public_subnet_ids
  security_group_ids   = [aws_security_group.alb.id]
  backend_target_port  = 5000
  backend_path_pattern = "/api/*"
  tags                 = local.common_tags
}

module "rds_postgres" {
  source = "../modules/rds_postgres"

  identifier              = "${var.project_name}-${var.environment}-postgres"
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  instance_class          = var.db_instance_class
  subnet_ids              = local.private_subnet_ids
  vpc_security_group_ids  = [aws_security_group.database.id]
  availability_zone       = data.aws_availability_zones.available.names[0]
  backup_retention_period = var.db_backup_retention_period
  skip_final_snapshot     = var.db_skip_final_snapshot
  # Security hardening: protect against accidental database deletion in production-like setups.
  deletion_protection     = var.db_deletion_protection
  tags                    = local.common_tags
}

module "frontend_hosting" {
  source = "../modules/s3_cloudfront_frontend"

  name_prefix            = "${var.project_name}-${var.environment}"
  api_origin_domain_name = module.api_alb_router.dns_name
  api_path_pattern       = "/api/*"
  tags                   = local.common_tags
}

module "backend_service" {
  source = "../modules/ecs_fargate_service"

  family             = "${var.project_name}-${var.environment}-backend"
  service_name       = "${var.project_name}-${var.environment}-backend"
  cluster_id         = module.ecs_cluster.id
  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  cpu                = var.backend_task_cpu
  memory             = var.backend_task_memory
  container_name     = "backend"
  image              = "${module.backend_ecr_repository.repository_url}:${var.backend_image_tag}"
  container_port     = 5000
  environment = [
    {
      name  = "ASPNETCORE_ENVIRONMENT"
      value = "Production"
    },
    {
      name  = "ASPNETCORE_URLS"
      value = "http://+:5000"
    },
    {
      name  = "ConnectionStrings__DefaultConnection"
      value = "Host=${module.rds_postgres.address};Port=5432;Database=${var.db_name};Username=${var.db_username};Password=${var.db_password}"
    },
    {
      name  = "CORS_ALLOWED_ORIGINS"
      value = "https://${module.frontend_hosting.domain_name}"
    },
    {
      name  = "ENABLE_HTTPS_REDIRECT"
      value = "false"
    },
    # Security hardening: runtime controls for auth, TLS enforcement, and abuse throttling.
    {
      name  = "Security__RequireAuthentication"
      value = tostring(var.security_require_authentication)
    },
    {
      name  = "Security__EnableHttpsRedirection"
      value = tostring(var.security_enable_https_redirection)
    },
    {
      name  = "Security__Jwt__Authority"
      value = var.security_jwt_authority
    },
    {
      name  = "Security__Jwt__Audience"
      value = var.security_jwt_audience
    },
    {
      name  = "Security__RateLimiting__PermitLimit"
      value = tostring(var.security_rate_limit_permit_limit)
    },
    {
      name  = "Security__RateLimiting__WindowSeconds"
      value = tostring(var.security_rate_limit_window_seconds)
    }
  ]
  log_group_name                     = "/ecs/${var.project_name}/${var.environment}/backend"
  aws_region                         = var.aws_region
  desired_count                      = var.service_desired_count
  subnets                            = local.ecs_service_subnet_ids
  security_groups                    = [aws_security_group.backend_service.id]
  assign_public_ip                   = true
  target_group_arn                   = module.api_alb_router.backend_target_group_arn
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200
  force_new_deployment               = true
  tags                               = local.common_tags

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_role_policy,
    module.rds_postgres,
    module.api_alb_router
  ]
}
