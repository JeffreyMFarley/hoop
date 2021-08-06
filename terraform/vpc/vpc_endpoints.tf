locals {
  interfaces = toset(["ecr.api", "ecr.dkr", "logs", "secretsmanager"])
}

data "aws_vpc_endpoint_service" "service" {
  for_each = local.interfaces
  service  = each.key
}

# -----------------------------------------------------------------------------
# Resources

resource "aws_vpc_endpoint" "interfaces" {
  for_each            = local.interfaces

  vpc_id              = aws_vpc.main.id
  service_name        = data.aws_vpc_endpoint_service.service[each.key].service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for o in aws_subnet.privatesubnets : o.id]

  security_group_ids = [
    "${aws_security_group.main.id}",
  ]

  tags = {
    Name = "${var.name} ${each.key} VPC Endpoint Interface"
  }
}


# S3
data "aws_vpc_endpoint_service" "s3" {
  service = "s3"
  service_type = "Gateway"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = data.aws_vpc_endpoint_service.s3.service_name
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [for o in aws_route_table.private_rt : o.id]

  tags = {
    Name = "S3 VPC Endpoint Gateway"
  }
}
