resource "random_string" "db_password" {
  length  = 16
  special = false
}

#################################################################################

resource "aws_db_instance" "main" {
  name       = var.db_name
  identifier = lower(var.name)

  allocated_storage     = 20
  engine                = "postgres"
  engine_version        = "12.5"
  instance_class        = "db.t2.micro"
  password              = random_string.db_password.result
  username              = var.db_username

  copy_tags_to_snapshot           = true
  enabled_cloudwatch_logs_exports = [
    "postgresql"
  ]
  max_allocated_storage           = 1000
  performance_insights_enabled    = true
  publicly_accessible             = true
  skip_final_snapshot             = true

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.id
  vpc_security_group_ids = [
    aws_security_group.main.id
  ]
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = lower("${var.name}-db-subnet-group")
  subnet_ids = concat(var.private_subnet_ids, var.public_subnet_ids)
}

resource "aws_security_group" "main" {
  name        = "${var.name}-db-sg"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name} Database security group"
  }

  ingress {
    protocol    = "tcp"
    description = "PostGRES"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = concat(
      var.private_subnet_cidr_blocks,
      var.developer_cidr_blocks
    )
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#################################################################################
##
##  AWS Secret Manager
##

##--------------------------------------------------------------
##  password

resource aws_secretsmanager_secret db_password {
  name = "${var.name}-db-password"
  recovery_window_in_days = 0
}

resource aws_secretsmanager_secret_version db_password {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_string.db_password.result
}
