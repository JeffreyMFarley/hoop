
locals {
  cidr_block = "10.0.0.0/24"
  public_subnets = {
    public-a = { cidr_block = "10.0.0.64/26", availability_zone = "${var.region}a" }
  }
  private_subnets = {
    private-a = { cidr_block = "10.0.0.128/26", availability_zone = "${var.region}a" }
    private-c = { cidr_block = "10.0.0.192/26", availability_zone = "${var.region}c" }
  }
}

# :+1: to https://adamtheautomator.com/terraform-vpc/
# :+1: to https://github.com/LukeMwila/aws-apigateway-vpc-ecs-fargate/blob/master/infra-modules/backend-environment/vpc/vpc.tf

 resource "aws_vpc" "main" {
   cidr_block           = local.cidr_block
   enable_dns_support   = true
   enable_dns_hostnames = true
   instance_tenancy     = "default"
 }

# -----------------------------------------------------------------------------
# Subnets

 resource "aws_subnet" "publicsubnets" {
   for_each          = local.public_subnets
   vpc_id            = aws_vpc.main.id
   cidr_block        = each.value.cidr_block
   availability_zone = each.value.availability_zone

   tags = {
     Name = "${var.name} public ${each.value.availability_zone}"
   }
 }

 resource "aws_subnet" "privatesubnets" {
   for_each          = local.private_subnets
   vpc_id            = aws_vpc.main.id
   cidr_block        = each.value.cidr_block
   availability_zone = each.value.availability_zone

   tags = {
     Name = "${var.name} private ${each.value.availability_zone}"
   }
 }

# -----------------------------------------------------------------------------
# Gateways

resource "aws_internet_gateway" "igw" {
   vpc_id =  aws_vpc.main.id
}

resource "aws_eip" "ngw" {
  for_each = local.private_subnets
  vpc      = true
}

resource "aws_nat_gateway" "ngw" {
  for_each      = local.private_subnets

  allocation_id = aws_eip.ngw[each.key].id
  subnet_id     = aws_subnet.privatesubnets[each.key].id

  depends_on    = [aws_internet_gateway.igw]
}

# -----------------------------------------------------------------------------
 # Route Tables

 resource "aws_route_table" "public_rt" {
    vpc_id =  aws_vpc.main.id
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
      Name = "${var.name} public"
    }
 }

 resource "aws_route_table" "private_rt" {
   for_each = local.private_subnets
   vpc_id   = aws_vpc.main.id

   route {
     cidr_block = "0.0.0.0/0"
     nat_gateway_id = aws_nat_gateway.ngw[each.key].id
   }

   tags = {
     Name = "${var.name} ${each.key}"
   }
 }

 resource "aws_route_table_association" "public_rtassociation" {
   for_each       = local.public_subnets
   subnet_id      = aws_subnet.publicsubnets[each.key].id
   route_table_id = aws_route_table.public_rt.id
 }

 resource "aws_route_table_association" "private_rtassociation" {
   for_each       = local.private_subnets
   subnet_id      = aws_subnet.privatesubnets[each.key].id
   route_table_id = aws_route_table.private_rt[each.key].id
 }

# -----------------------------------------------------------------------------
# Security Group

 resource "aws_security_group" "main" {
   name        = "${var.name}-vpc"
   vpc_id      = "${aws_vpc.main.id}"

   tags = {
     Name = "${var.name} VPC"
   }
 }

 resource "aws_security_group_rule" "private_subnet_ingress" {
   cidr_blocks       = [for o in aws_subnet.privatesubnets : o.cidr_block]
   description       = "SSL access to private subnets"
   from_port         = 443
   protocol          = "tcp"
   security_group_id = aws_security_group.main.id
   to_port           = 443
   type              = "ingress"
 }

 resource "aws_security_group_rule" "s3_access" {
   description       = "Access to S3 Gateway"
   from_port         = 443
   prefix_list_ids   = [aws_vpc_endpoint.s3.prefix_list_id]
   protocol          = "tcp"
   security_group_id = aws_security_group.main.id
   to_port           = 443
   type              = "egress"
 }

 resource "aws_security_group_rule" "private_subnet_egress" {
   cidr_blocks       = [for o in aws_subnet.privatesubnets : o.cidr_block]
   description       = "Allow all outgoing connections from the private subnets"
   from_port         = 0
   protocol          = "-1"
   security_group_id = aws_security_group.main.id
   to_port           = 0
   type              = "egress"
 }
