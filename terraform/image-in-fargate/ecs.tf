# :+1: to https://github.com/LukeMwila/aws-apigateway-vpc-ecs-fargate/tree/master/infra-modules/backend-environment/ecs-fargate
#         https://medium.com/swlh/deploy-container-in-ecs-fargate-behind-api-gateway-nlb-for-secure-optimal-accessibility-with-95542d5867c3

data "aws_ecr_image" "service_image" {
  repository_name = var.repository_name
  image_tag       = "latest"
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.name}-service"
  retention_in_days = 30
}

#################################################################################
# Service

resource "aws_ecs_service" "main" {
  name            = "${var.name}-service"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.main.family
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [var.security_group_id]
    subnets         = var.subnet_ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nlb_tg.arn
    container_name   = var.name
    container_port   = var.app_port
  }

  depends_on = [
    aws_ecs_task_definition.main,
    aws_security_group_rule.application
  ]
}

#################################################################################
# Task definition

resource "aws_ecs_task_definition" "main" {
  family             = "ecs-service-${var.name}"
  task_role_arn      = aws_iam_role.task_role.arn
  execution_role_arn = aws_iam_role.exec_role.arn
  network_mode       = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                = var.cpu
  memory             = var.memory
  container_definitions = jsonencode([
    {
      name : var.name,
      image : "${var.repository_url}:latest",
      cpu : var.cpu,
      memory : var.memory,
      networkMode : "awsvpc",
      logConfiguration: {
        logDriver: "awslogs",
        options: {
          awslogs-group: "${aws_cloudwatch_log_group.main.name}",
          awslogs-region: var.region,
          awslogs-stream-prefix: "ecs"
        }
      },
      portMappings : [
        {
          containerPort : var.app_port
          protocol : "tcp",
          hostPort : var.app_port
        }
      ],
      secrets: var.secrets,
      environment: var.environment
    }
  ])

  depends_on = [
    data.aws_ecr_image.service_image
  ]
}

#################################################################################
# Roles

resource "aws_iam_role" "task_role" {
  name = "ecs-task-role-${var.name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role" "exec_role" {
  name = "ecs-exec-role-${var.name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "exec_role" {
  name = "ecs-exec-policy-${var.name}"
  role = aws_iam_role.exec_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
              "*"
            ],
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:CreateLogGroup",
                "logs:DescribeLogStreams",
                "secretsmanager:GetSecretValue"
            ]
        }
    ]
}
EOF
}

#################################################################################
# Security Group Rules

# While it is nice that the service adds its own rule, there is the possibility
# of identical rules.  Adding app_port and host_port is not right, but helps
# with the "identical" rules
resource "aws_security_group_rule" "application" {
  security_group_id        = var.security_group_id
  protocol                 = "tcp"
  from_port                = var.app_port
  to_port                  = var.host_port
  type                     = "ingress"
  cidr_blocks              = var.subnet_cidr_blocks
}
