terraform {
  backend "s3" {
    bucket  = "tf-hoop-state-652840558528"
    key     = "dev/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

# -----------------------------------------------------------------------------
# Shared Resources
# -----------------------------------------------------------------------------

module "image_repo" {
  for_each = toset(["fortunes", "heroes", "names"])
  source   = "./ecr"
  name     = lower("${var.name}_${each.key}")
}

module "www_buckets" {
  for_each = toset([var.name])
  source   = "./www-bucket"
  name     = lower("${each.key}.${var.domain_name}")
}

module "rest_api" {
  source = "./rest_api"

  name            = var.name
  api_domain_name = "api.${var.domain_name}"
  domain_name     = var.domain_name
  region          = var.region
}

module "db" {
  source = "./db"

  name    = var.name
  db_name = lower(var.name)

  vpc_id                = module.vpc.vpc_id
  subnet_group_name     = module.vpc.database_subnet_group_name
  inbound_subnets       = module.vpc.private_subnets_cidr_blocks
  developer_cidr_blocks = var.developer_cidr_blocks
}

# -----------------------------------------------------------------------------
# Networking / ECS cluster
# -----------------------------------------------------------------------------

data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name             = var.name
  cidr             = "10.0.0.0/16"
  azs              = data.aws_availability_zones.available.names
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets   = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  database_subnets = ["10.0.7.0/24", "10.0.8.0/24"]

  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Name = "${var.name} VPC"
  }
}

module "ecs_cluster" {
  source = "./ecs-cluster"

  name = var.name
}

# Shared security group for the Fargate tasks. Each service module adds its own
# inbound rule for its application port; here we allow all egress so tasks can
# reach ECR, CloudWatch Logs, Secrets Manager and RDS.
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.name}-ecs-tasks"
  description = "Fargate task networking for ${var.name}"
  vpc_id      = module.vpc.vpc_id

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name} ECS tasks"
  }
}

# -----------------------------------------------------------------------------
# Individual services / applications
# -----------------------------------------------------------------------------

module "static_web" {
  source = "./static-web"

  domain_name          = var.domain_name
  bucket_and_host_name = module.www_buckets[var.name].name
  website_endpoint     = module.www_buckets[var.name].website_endpoint
}

module "fortunes" {
  source = "./image-in-lambda"

  name = "fortunes"

  repository_name        = module.image_repo["fortunes"].name
  repository_url         = module.image_repo["fortunes"].repo_url
  rest_api_execution_arn = module.rest_api.rest_api_execution_arn
  rest_api_id            = module.rest_api.rest_api_id
  parent_id              = module.rest_api.version_path_id
}

module "names" {
  source = "./image-in-fargate"

  name = "names"

  app_port  = 5000
  host_port = 5000

  region          = var.region
  repository_name = module.image_repo["names"].name
  repository_url  = module.image_repo["names"].repo_url

  parent_id   = module.rest_api.version_path_id
  rest_api_id = module.rest_api.rest_api_id

  cluster_id         = module.ecs_cluster.id
  security_group_id  = aws_security_group.ecs_tasks.id
  subnet_ids         = module.vpc.private_subnets
  subnet_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  vpc_id             = module.vpc.vpc_id
}

module "heroes" {
  source = "./image-in-fargate"

  name = "heroes"

  app_port  = 5000
  host_port = 5050

  region          = var.region
  repository_name = module.image_repo["heroes"].name
  repository_url  = module.image_repo["heroes"].repo_url

  parent_id   = module.rest_api.version_path_id
  rest_api_id = module.rest_api.rest_api_id

  cluster_id         = module.ecs_cluster.id
  security_group_id  = aws_security_group.ecs_tasks.id
  subnet_ids         = module.vpc.private_subnets
  subnet_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  vpc_id             = module.vpc.vpc_id

  environment = [
    { name = "POSTGRES_USER", value = module.db.user },
    { name = "POSTGRES_DB", value = module.db.db_name },
    { name = "POSTGRES_HOST", value = module.db.host },
  ]

  secrets = [
    { name = "POSTGRES_PASSWORD", valueFrom = module.db.password_arn },
  ]
}

# -----------------------------------------------------------------------------
# API Gateway deployment
#
# Lives here (not in the rest_api module) so it can depend on every service's
# methods/integrations. The `triggers` hash forces a fresh deployment whenever
# any service's routes change, and create_before_destroy avoids downtime. This
# is what lets a single `terraform apply` publish a complete API.
# -----------------------------------------------------------------------------

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = module.rest_api.rest_api_id

  triggers = {
    redeploy = sha1(jsonencode([
      module.fortunes.redeploy_hash,
      module.names.redeploy_hash,
      module.heroes.redeploy_hash,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    module.fortunes,
    module.names,
    module.heroes,
  ]
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = module.rest_api.rest_api_id
  stage_name    = "main"
}

resource "aws_api_gateway_method_settings" "main" {
  rest_api_id = module.rest_api.rest_api_id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
  }
}

resource "aws_api_gateway_base_path_mapping" "main" {
  api_id      = module.rest_api.rest_api_id
  stage_name  = aws_api_gateway_stage.main.stage_name
  domain_name = module.rest_api.domain_name
}
