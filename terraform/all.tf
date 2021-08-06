locals {
  make_fargate = false
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

module "vpc" {
  source = "./vpc"

  name   = var.name  # or name + environment
  region = var.region
}

module "ecs_cluster" {
  count = local.make_fargate ? 1 : 0
  source = "./ecs-cluster"

  name = var.name
}

module "db" {
  source = "./db"

  name    = var.name
  db_name = lower(var.name)

  vpc_id                     = module.vpc.vpc_id
  developer_cidr_blocks      = var.developer_cidr_blocks
  private_subnet_cidr_blocks = module.vpc.private_subnet_cidr_blocks
  private_subnet_ids         = module.vpc.private_subnet_ids
  public_subnet_ids          = module.vpc.public_subnet_ids
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

module "heroes" {
  count = local.make_fargate ? 1 : 0
  source = "./image-in-fargate"

  name      = "heroes"
  app_port  = 5000
  host_port = 5050
  region    = var.region

  repository_name    = module.image_repo["heroes"].name
  repository_url     = module.image_repo["heroes"].repo_url

  cluster_id         = local.make_fargate ? module.ecs_cluster.id : 0

  vpc_id             = module.vpc.vpc_id
  security_group_id  = module.vpc.security_group_id
  subnet_cidr_blocks = module.vpc.private_subnet_cidr_blocks
  subnet_ids         = module.vpc.private_subnet_ids

  rest_api_id        = module.rest_api.rest_api_id
  parent_id          = module.rest_api.version_path_id

  environment = [
    {"name": "POSTGRES_USER", "value": module.db.user},
    {"name": "POSTGRES_DB",   "value": module.db.db_name},
    {"name": "POSTGRES_HOST", "value": module.db.host}
  ]

  secrets = [
    {"name": "POSTGRES_PASSWORD", "valueFrom": module.db.password_arn}
  ]
}

module "names" {
  count = local.make_fargate ? 1 : 0
  source = "./image-in-fargate"

  name      = "names"
  app_port  = 5000
  host_port = 5000
  region    = var.region

  repository_name    = module.image_repo["names"].name
  repository_url     = module.image_repo["names"].repo_url

  cluster_id         = local.make_fargate ? module.ecs_cluster.id : 0

  vpc_id             = module.vpc.vpc_id
  security_group_id  = module.vpc.security_group_id
  subnet_cidr_blocks = module.vpc.private_subnet_cidr_blocks
  subnet_ids         = module.vpc.private_subnet_ids

  rest_api_id        = module.rest_api.rest_api_id
  parent_id          = module.rest_api.version_path_id
}
