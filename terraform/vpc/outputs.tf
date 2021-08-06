output "vpc_arn" {
  value = aws_vpc.main.arn
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [for o in aws_subnet.publicsubnets : o.id]
}

output "public_subnet_cidr_blocks" {
  value = [for o in aws_subnet.publicsubnets : o.cidr_block]
}

output "private_subnet_ids" {
  value = [for o in aws_subnet.privatesubnets : o.id]
}

output "private_subnet_cidr_blocks" {
  value = [for o in aws_subnet.privatesubnets : o.cidr_block]
}

output "security_group_id" {
  value = aws_security_group.main.id
}
