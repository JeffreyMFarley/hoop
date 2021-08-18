terraform {
  backend "s3" {
    bucket = "hoop-terraform"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
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
# EKS / Kubernetes
# -----------------------------------------------------------------------------

data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.47"

  name                 = "${var.name}"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  database_subnets     = ["10.0.7.0/24", "10.0.8.0/24"]

  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.name}" = "shared"
    "kubernetes.io/role/elb"            = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.name}" = "shared"
    "kubernetes.io/role/internal-elb"   = "1"
  }

  database_subnet_tags = {}

  tags = {
    Name = "${var.name} VPC"
  }
}

module "eks" {
  source                    = "terraform-aws-modules/eks/aws"
  version                   = "17.1.0"

  cluster_name              = var.name
  cluster_version           = "1.17"
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  subnets                   = module.vpc.private_subnets
  vpc_id                    = module.vpc.vpc_id

  kubeconfig_output_path    = "../k8s/kubeconfig.yaml"

  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 50
  }

  node_groups = {
    eks_nodes = {
      name_prefix      = "${var.name}-node"
      desired_capacity = 1
      max_capacity     = 3
      min_capacity     = 1

      instance_types = ["t3.large"]
    }
  }

  worker_groups = [
    {
      instance_type        = "t3.medium"
      asg_desired_capacity = 1
      asg_max_size         = 3
    }
  ]

  map_users = [
    {
      userarn  = "arn:aws:iam::${var.account_id}:user/jfarley"
      username = "jfarley"
      groups   = ["system:masters"]
    }
  ]
}

resource "aws_security_group_rule" "eks-node-ingress-cluster-dns" {
  protocol                 = "udp"
  description              = "Allow pods DNS"
  from_port                = 53
  to_port                  = 53
  security_group_id        = module.eks.worker_security_group_id
  cidr_blocks              = ["0.0.0.0/0"]
  type                     = "ingress"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
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
  source = "./image-in-eks"

  name = "names"

  app_port        = 5000
  host_port       = 5000

  repository_url  = module.image_repo["names"].repo_url

  parent_id       = module.rest_api.version_path_id
  rest_api_id     = module.rest_api.rest_api_id
}

module "heroes" {
  source = "./image-in-eks"

  name      = "heroes"

  app_port  = 5000
  host_port = 5050

  repository_url     = module.image_repo["heroes"].repo_url

  parent_id       = module.rest_api.version_path_id
  rest_api_id     = module.rest_api.rest_api_id

  db_host         = module.db.host
  db_name         = module.db.db_name
  db_user         = module.db.user
  db_password     = module.db.password
}
